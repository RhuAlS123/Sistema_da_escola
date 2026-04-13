/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect, useMemo } from 'react';
import { 
  Users, 
  DollarSign, 
  Calendar, 
  FileText, 
  Lock, 
  Unlock, 
  Search, 
  Plus, 
  Save, 
  Download, 
  LogOut,
  ChevronRight,
  AlertCircle,
  CheckCircle2,
  Clock,
  User as UserIcon,
  Trash2,
  Shield,
  UserPlus,
  Eye,
  EyeOff,
  Menu,
  X
} from 'lucide-react';
import { 
  format, 
  addMonths, 
  differenceInYears, 
  parseISO, 
  isAfter, 
  isBefore, 
  startOfMonth, 
  endOfMonth, 
  isSameMonth,
  addDays,
  isSameDay,
  isValid,
  parse,
  startOfDay,
  endOfDay,
} from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';
import { collection, doc, onSnapshot, setDoc, deleteDoc, query, where, getDocs } from 'firebase/firestore';
import { db } from './firebase';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';
import logo from './logo.jpeg';

function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/** yyyy-MM-dd (Firestore) → meia-noite local. parseISO usa UTC e pode deslocar o dia civil (ex.: Brasil). */
function parseDateOnlyLocal(ymd: string): Date {
  const t = ymd.trim();
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(t);
  if (!m) return parseISO(t);
  const y = Number(m[1]);
  const mo = Number(m[2]) - 1;
  const d = Number(m[3]);
  return new Date(y, mo, d, 0, 0, 0, 0);
}

/** Data curta padrão Brasil (dd/MM/yyyy) via locale pt-BR */
function fmtDataBR(date: Date | string): string {
  let d: Date;
  if (typeof date === 'string') {
    const t = date.trim();
    d = /^\d{4}-\d{2}-\d{2}$/.test(t) ? parseDateOnlyLocal(t) : parseISO(t);
  } else {
    d = date;
  }
  return isValid(d) ? format(d, 'P', {locale: ptBR}) : '—';
}

/** Data e hora padrão Brasil */
function fmtDataHoraBR(date: Date | string): string {
  let d: Date;
  if (typeof date === 'string') {
    const t = date.trim();
    d = /^\d{4}-\d{2}-\d{2}$/.test(t) ? parseDateOnlyLocal(t) : parseISO(t);
  } else {
    d = date;
  }
  return isValid(d)
    ? format(d, "dd/MM/yyyy 'às' HH:mm", {locale: ptBR})
    : '—';
}

/** Máscara enquanto digita: dd/mm/aaaa */
function maskDataBR(value: string): string {
  const d = value.replace(/\D/g, '').slice(0, 8);
  if (d.length <= 2) return d;
  if (d.length <= 4) return `${d.slice(0, 2)}/${d.slice(2)}`;
  return `${d.slice(0, 2)}/${d.slice(2, 4)}/${d.slice(4)}`;
}

/** Converte dd/MM/yyyy → yyyy-MM-dd (válido no calendário) */
function inputBRParaIso(s: string): string | null {
  const t = s.trim();
  if (!/^\d{2}\/\d{2}\/\d{4}$/.test(t)) return null;
  const parsed = parse(t, 'dd/MM/yyyy', new Date(), {locale: ptBR});
  return isValid(parsed) ? format(parsed, 'yyyy-MM-dd') : null;
}

/** Aceita yyyy-MM-dd ou dd/MM/yyyy (formulários) */
function normalizaDataFormulario(s: string): string | null {
  const t = s.trim();
  if (/^\d{4}-\d{2}-\d{2}$/.test(t)) {
    const p = parseDateOnlyLocal(t);
    return isValid(p) ? t : null;
  }
  return inputBRParaIso(t);
}

/**
 * Fim do dia civil (23:59:59.999 local) — vencimento ou data de pagamento só com dia/mês/ano.
 * Vale para qualquer dia: útil, fim de semana ou feriado (o calendário não “pula” esse dia).
 */
function lastMomentOfCalendarDay(d: Date): Date {
  return endOfDay(startOfDay(d));
}

function isBusinessDay(d: Date, holidays: string[]): boolean {
  const day = d.getDay();
  if (day === 0 || day === 6) return false;
  return !holidays.includes(format(d, 'yyyy-MM-dd'));
}

/**
 * Último instante sem juros no vencimento:
 * - Dia útil (e não feriado): até 23:59:59 desse dia.
 * - Fim de semana ou feriado: até 23:59:59 do primeiro dia útil a partir da data de vencimento
 *   (ex.: vence domingo → pode pagar até o fim da segunda sem juros).
 */
function lastMomentToPayWithoutLate(dueDate: Date, holidays: string[]): Date {
  let d = startOfDay(dueDate);
  while (!isBusinessDay(d, holidays)) {
    d = addDays(d, 1);
  }
  return lastMomentOfCalendarDay(d);
}

function cardFeeTotal(method: string, installments: number, taxaUnit: number): number {
  return method === 'Cartão de Crédito'
    ? Math.max(0, taxaUnit) * Math.max(1, installments)
    : 0;
}

interface AppUser {
  id?: string;
  username: string;
  role: 'Administrador' | 'Colaborador';
  isActive: boolean;
  password?: string;
  lastLogin?: string;
}

interface Installment {
  id: string;
  dueDate: string;
  paymentDate?: string;
  amountPaid?: number;
  remainingAmount?: number;
  remainingPaymentDate?: string;
  paymentMethod?: string;
  creditInstallments?: number;
  creditFee?: number;
  attendant?: string;
  status: 'Em aberto' | 'Atrasado' | 'Pago' | 'Pago Parcialmente';
}

interface FinancialData {
  enrollmentDate: string;
  coursePackage: string;
  classes: string;
  dueDay: number;
  durationMonths: number;
  monthlyFee: number;
  promoLoss: number;
  dailyInterest: number;
  contractFee: number;
  retestFee: number;
  fineFee: number;
  status: 'Mensalista' | 'Bolsista';
  observations?: string;
  isLocked: boolean;
}

interface Student {
  id: string;
  guardianName: string;
  phone: string;
  cpf: string;
  rg: string;
  birthDate: string;
  address: string;
  city: string;
  relationship: string;
  studentName: string;
  studentBirthDate: string;
  age: number;
  techClassTime?: string;
  englishClassTime?: string;
  retest?: string;
  contractCopy?: string;
  financial?: FinancialData;
  installments: Installment[];
}


export default function App() {
  const [currentUser, setCurrentUser] = useState<AppUser | null>(() => {
    const savedUser = localStorage.getItem('@ICPRO:user');
    return savedUser ? JSON.parse(savedUser) : null;
  });
  const [activeTab, setActiveTab] = useState<'cadastro' | 'financeiro' | 'parcelas' | 'relatorios' | 'usuarios'>('cadastro');
  const [students, setStudents] = useState<Student[]>([]);
  const [selectedStudentId, setSelectedStudentId] = useState<string | null>(null);
  const [loginError, setLoginError] = useState<string | null>(null);
  const [isLoggingIn, setIsLoggingIn] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [holidays, setHolidays] = useState<string[]>([]);

  useEffect(() => {
    setIsLoading(true);
    const unsub = onSnapshot(collection(db, 'students'), (snapshot) => {
      const studentsData = snapshot.docs.map(doc => ({ ...doc.data(), id: doc.id } as Student));
      setStudents(studentsData);
      setIsLoading(false);
    });

    const fetchHolidays = async () => {
      try {
        const year = new Date().getFullYear();
        const [res1, res2] = await Promise.all([
          fetch(`https://brasilapi.com.br/api/feriados/v1/${year - 1}`),
          fetch(`https://brasilapi.com.br/api/feriados/v1/${year}`),
        ]);
        const data1 = await res1.json();
        const data2 = await res2.json();
        setHolidays([...data1, ...data2].map((h: {date: string}) => h.date));
      } catch (error) {
        console.error('Erro ao buscar feriados na API:', error);
      }
    };
    void fetchHolidays();

    return () => unsub();
  }, []);

  const selectedStudent = useMemo(() => 
    students.find(s => s.id === selectedStudentId), 
  [students, selectedStudentId]);

  const handleLogin = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsLoggingIn(true);
    const formData = new FormData(e.currentTarget);
    const username = formData.get('username') as string;
    const password = formData.get('password') as string;
    const rememberMe = formData.get('rememberMe') === 'on';

    try {
      const q = query(collection(db, 'users'), where('username', '==', username), where('password', '==', password));
      const snap = await getDocs(q);

      if (!snap.empty) {
        const userDoc = snap.docs[0];
        const userData = userDoc.data() as AppUser;

        if (!userData.isActive) {
          setLoginError('Acesso Negado: Este usuário foi bloqueado pelo Administrador.');
        } else {
          await setDoc(doc(db, 'users', userDoc.id), { lastLogin: new Date().toISOString() }, { merge: true });
          const userToSave = { ...userData, id: userDoc.id };
          setCurrentUser(userToSave);
          if (rememberMe) {
            localStorage.setItem('@ICPRO:user', JSON.stringify(userToSave));
            localStorage.setItem('@ICPRO:savedCredentials', JSON.stringify({ username, password }));
          } else {
            localStorage.removeItem('@ICPRO:savedCredentials');
          }
          setLoginError(null);
        }
      } else {
        setLoginError('Usuário ou senha incorretos.');
      }
    } catch (error: unknown) {
      console.error('Erro no login:', error);
      const code =
        error && typeof error === 'object' && 'code' in error
          ? String((error as {code: unknown}).code)
          : '';
      if (code === 'permission-denied') {
        setLoginError(
          'Acesso negado pelo Firestore. Publica as regras (firestore.rules) ou abre Regras na consola Firebase.',
        );
      } else {
        setLoginError('Erro de conexão. Tente novamente mais tarde.');
      }
    } finally {
      setIsLoggingIn(false);
    }
  };

  const handleLogout = () => {
    setCurrentUser(null);
    setSelectedStudentId(null);
    setActiveTab('cadastro');
    localStorage.removeItem('@ICPRO:user');
  };

  useEffect(() => {
    if (!currentUser?.id) return;

    const unsub = onSnapshot(doc(db, 'users', currentUser.id), (docSnap) => {
      if (!docSnap.exists() || docSnap.data()?.isActive === false) {
        setCurrentUser(null);
        setSelectedStudentId(null);
        setActiveTab('cadastro');
        localStorage.removeItem('@ICPRO:user');
        setLoginError(!docSnap.exists() ? 'Sua conta foi excluída pelo administrador.' : 'Seu acesso foi bloqueado pelo administrador.');
      }
    });

    return () => unsub();
  }, [currentUser?.id]);

  if (!currentUser || isLoggingIn) {
    return <LoginScreen onLogin={handleLogin} error={loginError} isLoggingIn={isLoggingIn} />;
  }

  return (
    <div className="h-[100dvh] w-full bg-slate-950 text-slate-300 flex flex-col md:flex-row overflow-hidden relative">
      {/* Mobile Top Bar */}
      <div className="md:hidden flex items-center justify-between bg-slate-900 border-b border-slate-800 p-4 shrink-0 sticky top-0 z-30">
        <div className="flex items-center gap-3">
          <img src={logo} alt="ICPRO Logo" className="h-8 w-auto bg-white p-1 rounded-md" />
          <h1 className="font-bold text-lg tracking-tight text-white">ICPRO</h1>
        </div>
        <button onClick={() => setIsMobileMenuOpen(true)} className="text-slate-400 hover:text-white p-1 transition-colors">
          <Menu className="w-6 h-6" />
        </button>
      </div>

      {/* Mobile Overlay */}
      {isMobileMenuOpen && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm z-40 md:hidden" onClick={() => setIsMobileMenuOpen(false)} />
      )}

      {/* Sidebar / Navigation */}
      <nav className={cn(
        "fixed inset-y-0 left-0 z-50 w-72 shrink-0 bg-slate-900 border-r border-slate-800 text-white p-4 flex flex-col transform transition-transform duration-300 ease-in-out md:relative md:translate-x-0 md:w-64 h-[100dvh]",
        isMobileMenuOpen ? "translate-x-0" : "-translate-x-full"
      )}>
        <div className="flex items-center justify-between mb-8 px-2">
          <div className="flex items-center gap-3">
            <img src={logo} alt="ICPRO Logo" className="hidden md:block h-10 w-auto bg-white p-1 rounded-lg" />
            <h1 className="hidden md:block font-bold text-xl tracking-tight">ICPRO</h1>
            <span className="md:hidden font-bold text-lg text-slate-400">Menu</span>
          </div>
          <button className="md:hidden text-slate-400 hover:text-white p-1" onClick={() => setIsMobileMenuOpen(false)}>
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="flex-1 space-y-1 overflow-y-auto">
          <NavButton 
            active={activeTab === 'cadastro'} 
            onClick={() => { setActiveTab('cadastro'); setIsMobileMenuOpen(false); }}
            icon={<UserIcon className="w-5 h-5" />}
            label="Cadastro Geral"
          />
          <NavButton 
            active={activeTab === 'financeiro'} 
            onClick={() => { setActiveTab('financeiro'); setIsMobileMenuOpen(false); }}
            icon={<DollarSign className="w-5 h-5" />}
            label="Financeiro"
          />
          <NavButton 
            active={activeTab === 'parcelas'} 
            onClick={() => { setActiveTab('parcelas'); setIsMobileMenuOpen(false); }}
            icon={<Calendar className="w-5 h-5" />}
            label="Parcelas"
          />
          <NavButton 
            active={activeTab === 'relatorios'} 
            onClick={() => { setActiveTab('relatorios'); setIsMobileMenuOpen(false); }}
            icon={<FileText className="w-5 h-5" />}
            label="Relatórios"
          />
          {currentUser.role === 'Administrador' && (
            <NavButton 
              active={activeTab === 'usuarios'} 
              onClick={() => { setActiveTab('usuarios'); setIsMobileMenuOpen(false); }}
              icon={<Shield className="w-5 h-5" />}
              label="Gerenciar Usuários"
            />
          )}
        </div>

        <div className="mt-auto pt-4 border-t border-slate-800">
          <div className="flex items-center gap-3 px-2 mb-4">
            <div className="w-8 h-8 rounded-full bg-slate-700 flex items-center justify-center text-xs font-bold">
              {currentUser.username[0].toUpperCase()}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium truncate">{currentUser.username}</p>
              <p className="text-xs text-slate-400">{currentUser.role}</p>
            </div>
          </div>
          <button 
            onClick={handleLogout}
            className="w-full flex items-center gap-2 px-3 py-2 text-sm text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg transition-colors"
          >
            <LogOut className="w-4 h-4" />
            Sair do Sistema
          </button>
        </div>
      </nav>

      {/* Main Content */}
      <main className="flex-1 h-[calc(100dvh-73px)] md:h-[100dvh] overflow-y-auto p-4 md:p-8 relative">
        <div className="max-w-5xl mx-auto">
          {activeTab === 'cadastro' && (
            <CadastroTab 
              students={students} 
              setStudents={setStudents} 
              selectedStudent={selectedStudent}
              setSelectedStudentId={setSelectedStudentId}
              onSave={() => setActiveTab('financeiro')}
            />
          )}
          {activeTab === 'financeiro' && (
            <FinanceiroTab 
              selectedStudent={selectedStudent}
              setStudents={setStudents}
              currentUser={currentUser}
            />
          )}
          {activeTab === 'parcelas' && (
            <ParcelasTab 
              selectedStudent={selectedStudent}
              setStudents={setStudents}
              currentUser={currentUser}
              holidays={holidays}
            />
          )}
          {activeTab === 'relatorios' && (
            <RelatoriosTab students={students} currentUser={currentUser} holidays={holidays} />
          )}
          {activeTab === 'usuarios' && currentUser.role === 'Administrador' && (
            <UsuariosTab />
          )}
        </div>
      </main>
    </div>
  );
}


function LoginScreen({ onLogin, error, isLoggingIn }: { onLogin: (e: React.FormEvent<HTMLFormElement>) => void, error: string | null, isLoggingIn: boolean }) {
  const [showPassword, setShowPassword] = useState(false);

  const savedCreds = useMemo(() => {
    const saved = localStorage.getItem('@ICPRO:savedCredentials');
    return saved ? JSON.parse(saved) : null;
  }, []);

  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4">
      <div className="w-full max-w-md bg-slate-900 rounded-2xl shadow-xl p-8 border border-slate-800">
        <div className="text-center mb-8">
          <img src={logo} alt="ICPRO Logo" className="w-32 h-auto mx-auto mb-4 bg-white rounded-2xl p-3 shadow-lg" />
          <h1 className="text-2xl font-bold text-slate-100">Sistema de Cadastro ICPRO</h1>
          <p className="text-slate-400">Gestão de Alunos e Financeiro</p>
        </div>

        <form onSubmit={onLogin} className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-slate-400 mb-1">Usuário</label>
            <input 
              type="text"
              name="username"
              defaultValue={savedCreds?.username || ''}
              placeholder="Digite seu usuário..."
              className="w-full px-4 py-2 bg-slate-800 border border-slate-700 text-slate-100 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-400 mb-1">Senha</label>
            <div className="relative">
              <input 
                type={showPassword ? "text" : "password"} 
                name="password"
                defaultValue={savedCreds?.password || ''}
                placeholder="••••••••"
                className="w-full px-4 py-2 bg-slate-800 border border-slate-700 text-slate-100 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all pr-12"
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-300 transition-colors"
              >
                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
          </div>

          <label className="flex items-center gap-3 cursor-pointer group w-max">
            <div className="relative flex items-center">
              <input type="checkbox" name="rememberMe" defaultChecked={!!savedCreds} className="sr-only peer" />
              <div className="w-10 h-5 bg-slate-950 border border-slate-700 rounded-full peer-checked:bg-blue-600 peer-checked:border-blue-600 transition-colors shadow-inner"></div>
              <div className="absolute left-[3px] w-3.5 h-3.5 bg-slate-400 rounded-full transition-all duration-300 peer-checked:translate-x-[20px] peer-checked:bg-white shadow-sm"></div>
            </div>
            <span className="text-sm font-medium text-slate-400 group-hover:text-slate-200 transition-colors select-none">Lembrar de mim</span>
          </label>

          {error && (
            <div className="flex items-center gap-2 text-red-400 text-sm bg-red-500/10 p-3 rounded-lg">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          <button 
            type="submit"
            disabled={isLoggingIn}
            className="w-full py-3 bg-blue-600 text-white font-bold rounded-lg shadow-lg shadow-blue-500/40 transition-all duration-200 transform hover:-translate-y-1 hover:shadow-2xl hover:shadow-blue-500/30 active:translate-y-0 active:shadow-lg disabled:opacity-50"
          >
            {isLoggingIn ? 'Autenticando...' : 'Entrar no Sistema'}
          </button>
        </form>
      </div>
    </div>
  );
}

function NavButton({ active, onClick, icon, label }: { active: boolean, onClick: () => void, icon: React.ReactNode, label: string }) {
  return (
    <button 
      onClick={onClick}
      className={cn(
        "w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all",
        active 
          ? "bg-blue-600 text-white shadow-lg shadow-blue-900/20" 
          : "text-slate-400 hover:text-white hover:bg-slate-800"
      )}
    >
      {icon}
      {label}
    </button>
  );
}

function CadastroTab({ students, setStudents, selectedStudent, setSelectedStudentId, onSave }: { 
  students: Student[], 
  setStudents: React.Dispatch<React.SetStateAction<Student[]>>,
  selectedStudent?: Student,
  setSelectedStudentId: (id: string | null) => void,
  onSave: () => void
}) {
  const [isSearching, setIsSearching] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [dynamicAge, setDynamicAge] = useState(selectedStudent?.age || 0);
  const [isSaving, setIsSaving] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    setDynamicAge(selectedStudent?.age || 0);
  }, [selectedStudent]);

  const maskCPF = (value: string) => {
    return value
      .replace(/\D/g, '')
      .replace(/(\d{3})(\d)/, '$1.$2')
      .replace(/(\d{3})(\d)/, '$1.$2')
      .replace(/(\d{3})(\d{1,2})/, '$1-$2')
      .replace(/(-\d{2})\d+?$/, '$1');
  };

  const calculateAge = (birthDate: string) => {
    if (!birthDate) return 0;
    const parsed = parseDateOnlyLocal(birthDate);
    if (isNaN(parsed.getTime())) return 0;
    return differenceInYears(new Date(), parsed);
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsSaving(true);
    const formData = new FormData(e.currentTarget);
    const data = Object.fromEntries(formData.entries());
    const birthIso = normalizaDataFormulario(data.birthDate as string);
    const studentBirthIso = normalizaDataFormulario(data.studentBirthDate as string);
    if (!birthIso) {
      alert('Data de nascimento do responsável inválida. Use dd/mm/aaaa.');
      setIsSaving(false);
      return;
    }
    if (!studentBirthIso) {
      alert('Data de nascimento do aluno inválida. Use dd/mm/aaaa.');
      setIsSaving(false);
      return;
    }
    const newId = selectedStudent?.id || doc(collection(db, 'students')).id;
    
    const newStudent: Student = {
      id: newId,
      guardianName: data.guardianName as string,
      phone: data.phone as string,
      cpf: data.cpf as string,
      rg: data.rg as string,
      birthDate: birthIso,
      address: data.address as string,
      city: data.city as string,
      relationship: data.relationship as string,
      studentName: data.studentName as string,
      studentBirthDate: studentBirthIso,
      age: calculateAge(studentBirthIso),
      techClassTime: data.techClassTime as string,
      englishClassTime: data.englishClassTime as string,
      retest: data.retest as string,
      contractCopy: data.contractCopy as string,
      installments: selectedStudent?.installments || []
    };

    if (selectedStudent?.financial) {
      newStudent.financial = selectedStudent.financial;
    }

    try {
      const studentRef = doc(db, 'students', newStudent.id);
      await setDoc(studentRef, newStudent, { merge: true });
      setSelectedStudentId(newStudent.id);
      onSave();
    } catch (error: any) {
      console.error("Erro ao salvar aluno:", error);
      alert("Erro ao salvar o aluno: " + (error?.message || "Desconhecido"));
    } finally {
      setIsSaving(false);
    }
  };

  const executeDelete = async () => {
    if (!selectedStudent?.id) return;
    setIsDeleting(true);
    try {
      await deleteDoc(doc(db, 'students', selectedStudent.id));
      setSelectedStudentId(null);
      setShowDeleteModal(false);
    } catch (error) {
      console.error("Erro ao remover aluno:", error);
      alert("Erro ao remover aluno.");
    } finally {
      setIsDeleting(false);
    }
  };

  const filteredStudents = students
    .filter(s => 
      s.studentName.toLowerCase().includes(searchQuery.toLowerCase()) || 
      s.guardianName.toLowerCase().includes(searchQuery.toLowerCase())
    )
    .sort((a, b) => a.studentName.localeCompare(b.studentName));

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <h2 className="text-2xl font-bold text-slate-100">Cadastro de Aluno</h2>
        <div className="flex flex-col sm:flex-row gap-2 w-full sm:w-auto">
          <button 
            onClick={() => { setSelectedStudentId(null); setIsSearching(false); }}
            className="flex-1 sm:flex-none flex items-center justify-center gap-2 px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-sm font-medium text-slate-300 hover:bg-slate-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Novo Aluno
          </button>
          <button 
            onClick={() => setIsSearching(!isSearching)}
            className="flex-1 sm:flex-none flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-500 active:bg-blue-700 transition-colors"
          >
            <Search className="w-4 h-4" />
            Localizar
          </button>
        </div>
      </div>

      {isSearching ? (
        <div className="bg-slate-900 rounded-xl border border-slate-800 overflow-hidden">
          <div className="p-4 border-b border-slate-800">
            <input 
              type="text" 
              placeholder="Buscar por nome do aluno ou responsável..."
              className="w-full px-4 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg outline-none focus:ring-2 focus:ring-blue-500"
              value={searchQuery}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearchQuery(e.target.value)}
            />
          </div>
          <div className="max-h-96 overflow-y-auto">
            {filteredStudents.map(s => (
              <button 
                key={s.id}
                onClick={() => { setSelectedStudentId(s.id); setIsSearching(false); }}
                className="w-full flex items-center justify-between p-4 hover:bg-slate-800 border-b border-slate-800 last:border-0 text-left transition-colors"
              >
                <div>
                  <p className="font-semibold text-slate-100">{s.studentName}</p>
                  <p className="text-xs text-slate-400">Resp: {s.guardianName}</p>
                </div>
                <ChevronRight className="w-4 h-4 text-slate-300" />
              </button>
            ))}
            {filteredStudents.length === 0 && (
              <div className="p-8 text-center text-slate-400">Nenhum aluno encontrado</div>
            )}
          </div>
        </div>
      ) : (
        <form key={selectedStudent?.id || 'new'} onSubmit={handleSubmit} className="bg-slate-900 rounded-xl border border-slate-800 shadow-sm overflow-hidden">
          <div className="p-6 space-y-8">
            {/* Responsável */}
            <section>
              <h3 className="text-sm font-bold text-blue-400 uppercase tracking-wider mb-4">Dados do Responsável</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="md:col-span-2">
                  <label className="block text-xs font-medium text-slate-400 mb-1">Nome Completo</label>
                  <input name="guardianName" defaultValue={selectedStudent?.guardianName} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-400 mb-1">Telefone</label>
                  <input name="phone" defaultValue={selectedStudent?.phone} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-400 mb-1">CPF</label>
                  <input 
                    name="cpf" 
                    defaultValue={selectedStudent?.cpf} 
                    onChange={(e: React.ChangeEvent<HTMLInputElement>) => e.target.value = maskCPF(e.target.value)}
                    required 
                    className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg outline-none focus:ring-2 focus:ring-blue-500" 
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-400 mb-1">RG</label>
                  <input name="rg" defaultValue={selectedStudent?.rg} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-400 mb-1">Data de Nascimento</label>
                  <input
                    name="birthDate"
                    type="text"
                    inputMode="numeric"
                    placeholder="dd/mm/aaaa"
                    autoComplete="off"
                    defaultValue={selectedStudent?.birthDate ? fmtDataBR(selectedStudent.birthDate) : ''}
                    onChange={(e) => {
                      e.target.value = maskDataBR(e.target.value);
                    }}
                    required
                    maxLength={10}
                    className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div className="md:col-span-2">
                  <label className="block text-xs font-medium text-slate-400 mb-1">Endereço</label>
                  <input name="address" defaultValue={selectedStudent?.address} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-400 mb-1">Cidade</label>
                  <input name="city" defaultValue={selectedStudent?.city} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-400 mb-1">Parentesco</label>
                  <select name="relationship" defaultValue={selectedStudent?.relationship} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg outline-none focus:ring-2 focus:ring-blue-500">
                    <option value="Pai">Pai</option>
                    <option value="Mãe">Mãe</option>
                    <option value="Tio(a)">Tio(a)</option>
                    <option value="Avô(ó)">Avô(ó)</option>
                    <option value="Outros">Outros</option>
                  </select>
                </div>
              </div>
            </section>

            {/* Aluno */}
            <section>
              <h3 className="text-sm font-bold text-blue-400 uppercase tracking-wider mb-4">Dados do Aluno</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="md:col-span-2">
                  <label className="block text-xs font-medium text-slate-400 mb-1">Nome do Aluno</label>
                  <input name="studentName" defaultValue={selectedStudent?.studentName} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-400 mb-1">Data de Nascimento</label>
                  <input
                    name="studentBirthDate"
                    type="text"
                    inputMode="numeric"
                    placeholder="dd/mm/aaaa"
                    autoComplete="off"
                    defaultValue={selectedStudent?.studentBirthDate ? fmtDataBR(selectedStudent.studentBirthDate) : ''}
                    onChange={(e) => {
                      e.target.value = maskDataBR(e.target.value);
                      const iso = inputBRParaIso(e.target.value);
                      if (iso) setDynamicAge(calculateAge(iso));
                    }}
                    required
                    maxLength={10}
                    className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-400 mb-1">Idade (Automático)</label>
                  <div className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-slate-300">
                    {dynamicAge} anos
                  </div>
                </div>
              </div>
            </section>

            {/* Informações Adicionais */}
            <section>
              <h3 className="text-sm font-bold text-blue-400 uppercase tracking-wider mb-4">Informações Adicionais</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-slate-400 mb-1">Turma/Horário Tecnologia</label>
                  <input name="techClassTime" defaultValue={selectedStudent?.techClassTime} className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-400 mb-1">Turma/Horário Inglês</label>
                  <input name="englishClassTime" defaultValue={selectedStudent?.englishClassTime} className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-400 mb-1">Reteste</label>
                  <input name="retest" defaultValue={selectedStudent?.retest} className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-400 mb-1">2ª Via do Contrato</label>
                  <input name="contractCopy" defaultValue={selectedStudent?.contractCopy} className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg outline-none focus:ring-2 focus:ring-blue-500" />
                </div>
              </div>
            </section>
          </div>

          <div className="p-4 bg-slate-900/50 border-t border-slate-800 flex flex-col sm:flex-row justify-between items-center gap-4">
            {selectedStudent ? (
              <button
                type="button"
                onClick={() => setShowDeleteModal(true)}
                className="w-full sm:w-auto flex items-center justify-center gap-2 px-4 py-2 bg-red-500/10 text-red-500 font-bold rounded-lg hover:bg-red-500/20 transition-colors"
              >
                <Trash2 className="w-4 h-4" />
                Excluir Aluno
              </button>
            ) : (
              <div className="hidden sm:block"></div>
            )}
            <button 
              type="submit"
              disabled={isSaving}
              className="w-full sm:w-auto flex items-center justify-center gap-2 px-6 py-2.5 bg-blue-600 text-white font-bold rounded-lg shadow-lg shadow-blue-500/40 transition-all duration-200 transform hover:-translate-y-1 hover:shadow-2xl hover:shadow-blue-500/30 active:translate-y-0 active:shadow-lg disabled:opacity-50 disabled:pointer-events-none"
            >
              <Save className="w-4 h-4" />
              {isSaving ? 'Salvando...' : 'Salvar e Continuar'}
            </button>
          </div>
        </form>
      )}

      {/* Modal de Exclusão */}
      {showDeleteModal && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-slate-900 rounded-2xl shadow-2xl w-full max-w-md p-6 border border-slate-700">
            <div className="flex items-center gap-3 mb-4 text-red-500">
              <AlertCircle className="w-6 h-6" />
              <h3 className="text-lg font-bold">Excluir Aluno</h3>
            </div>
            <p className="text-sm text-slate-400 mb-6">
              Tem certeza que deseja apagar o aluno <strong className="text-slate-200">{selectedStudent?.studentName}</strong> do sistema? Esta ação é irreversível e excluirá todas as parcelas!
            </p>
            <div className="flex gap-3">
              <button 
                onClick={() => setShowDeleteModal(false)}
                disabled={isDeleting}
                className="flex-1 py-2.5 bg-slate-800 text-slate-300 font-bold rounded-lg hover:bg-slate-700 transition-colors disabled:opacity-50"
              >
                Cancelar
              </button>
              <button 
                onClick={executeDelete}
                disabled={isDeleting}
                className="flex-1 py-2.5 bg-red-600 text-white font-bold rounded-lg hover:bg-red-500 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
              >
                {isDeleting ? 'Excluindo...' : 'Sim, Excluir'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function FinanceiroTab({ selectedStudent, setStudents, currentUser }: { 
  selectedStudent?: Student, 
  setStudents: React.Dispatch<React.SetStateAction<Student[]>>,
  currentUser: AppUser
}) {
  const [isOtherPackage, setIsOtherPackage] = useState(false);
  const [showUnlockModal, setShowUnlockModal] = useState(false);
  const [unlockPassword, setUnlockPassword] = useState('');
  const [unlockError, setUnlockError] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  if (!selectedStudent) {
    return (
      <div className="flex flex-col items-center justify-center p-12 bg-slate-900 rounded-xl border border-dashed border-slate-700 text-slate-400">
        <Search className="w-12 h-12 mb-4 opacity-20" />
        <p className="text-center">Selecione um aluno na aba 'Cadastro Geral' para ver os dados financeiros.</p>
      </div>
    );
  }

  const isLocked = selectedStudent.financial?.isLocked || false;

  const handleUnlock = async () => {
    let isValidAdmin = false;
    
    const q = query(collection(db, 'users'), where('role', '==', 'Administrador'), where('password', '==', unlockPassword));
    const snap = await getDocs(q);
    if (!snap.empty) isValidAdmin = true;

    if (isValidAdmin) {
        const studentRef = doc(db, 'students', selectedStudent.id);
        await setDoc(studentRef, {
          financial: { ...selectedStudent.financial, isLocked: false }
        }, { merge: true });
  
        setShowUnlockModal(false);
        setUnlockPassword('');
        setUnlockError(false);
    } else {
        setUnlockError(true);
    }
  };

  const generateInstallments = (financial: FinancialData): Installment[] => {
    const installments: Installment[] = [];
    const startDate = parseDateOnlyLocal(financial.enrollmentDate);
    
    for (let i = 0; i < financial.durationMonths; i++) {
      const dueDate = addMonths(startDate, i);
      dueDate.setDate(financial.dueDay);
      
      installments.push({
        id: doc(collection(db, 'temp')).id,
        dueDate: format(dueDate, 'yyyy-MM-dd'),
        attendant: undefined,
        status: 'Em aberto'
      });
    }
    return installments;
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (isLocked) return;
    setIsSaving(true);

    const formData = new FormData(e.currentTarget);
    const data = Object.fromEntries(formData.entries());
    const enrollmentIso = normalizaDataFormulario(data.enrollmentDate as string);
    if (!enrollmentIso) {
      alert('Data de matrícula inválida. Use dd/mm/aaaa.');
      setIsSaving(false);
      return;
    }

    const financial: FinancialData = {
      enrollmentDate: enrollmentIso,
      coursePackage: data.coursePackage === 'Outros' ? data.customPackage as string : data.coursePackage as string,
      classes: data.classes as string,
      dueDay: parseInt(data.dueDay as string),
      durationMonths: parseInt(data.durationMonths as string),
      monthlyFee: parseFloat(data.monthlyFee as string),
      promoLoss: parseFloat(data.promoLoss as string),
      dailyInterest: parseFloat(data.dailyInterest as string),
      contractFee: parseFloat(data.contractFee as string),
      retestFee: parseFloat(data.retestFee as string),
      fineFee: parseFloat(data.fineFee as string),
      status: data.status as 'Mensalista' | 'Bolsista',
      observations: data.observations as string,
      isLocked: true
    };

    const updatedStudent = {
      ...selectedStudent,
      financial,
      installments: generateInstallments(financial),
    };
    const studentRef = doc(db, 'students', selectedStudent.id);
    try {
      await setDoc(studentRef, updatedStudent);
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-slate-100">Cadastro Financeiro</h2>
          <p className="text-slate-400">Aluno: <span className="font-semibold text-slate-200">{selectedStudent.studentName}</span></p>
        </div>
        {isLocked && (
          <button 
            onClick={() => setShowUnlockModal(true)}
            className="w-full sm:w-auto flex items-center justify-center gap-2 px-4 py-2 bg-amber-500/10 text-amber-400 border border-amber-500/30 rounded-lg text-sm font-bold hover:bg-amber-500/20 transition-colors"
          >
            <Lock className="w-4 h-4" />
            Desbloquear Edição
          </button>
        )}
      </div>

      <form onSubmit={handleSubmit} className="bg-slate-900 rounded-xl border border-slate-800 shadow-sm overflow-hidden">
        <div className="p-6 space-y-8">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-medium text-slate-400 mb-1">Data de Matrícula</label>
              <input
                name="enrollmentDate"
                type="text"
                inputMode="numeric"
                placeholder="dd/mm/aaaa"
                autoComplete="off"
                defaultValue={
                  selectedStudent.financial?.enrollmentDate
                    ? fmtDataBR(selectedStudent.financial.enrollmentDate)
                    : ''
                }
                onChange={(e) => {
                  if (!isLocked) e.target.value = maskDataBR(e.target.value);
                }}
                disabled={isLocked}
                required
                maxLength={10}
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg disabled:opacity-50"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-400 mb-1">Pacote de Cursos</label>
              <select 
                name="coursePackage" 
                defaultValue={selectedStudent.financial?.coursePackage} 
                disabled={isLocked}
                onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setIsOtherPackage(e.target.value === 'Outros')}
                required 
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg disabled:opacity-50"
              >
                <option value="Tecnologia">Tecnologia</option>
                <option value="Inglês">Inglês</option>
                <option value="Combo">Combo</option>
                <option value="Outros">Outros</option>
              </select>
            </div>
            {isOtherPackage && (
              <div>
                <label className="block text-xs font-medium text-slate-400 mb-1">Especifique o Pacote</label>
                <input name="customPackage" disabled={isLocked} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg" />
              </div>
            )}
            <div>
              <label className="block text-xs font-medium text-slate-400 mb-1">Vencimento (Dia)</label>
              <input type="number" name="dueDay" min="1" max="31" defaultValue={selectedStudent.financial?.dueDay || 10} disabled={isLocked} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg" />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-400 mb-1">Duração (Meses)</label>
              <input type="number" name="durationMonths" defaultValue={selectedStudent.financial?.durationMonths || 12} disabled={isLocked} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg" />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-400 mb-1">Status</label>
              <select name="status" defaultValue={selectedStudent.financial?.status} disabled={isLocked} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg">
                <option value="Mensalista">Mensalista</option>
                <option value="Bolsista">Bolsista</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 pt-4 border-t border-slate-800">
            <div>
              <label className="block text-xs font-medium text-slate-400 mb-1">Mensalidade (R$)</label>
              <input type="number" step="0.01" name="monthlyFee" defaultValue={selectedStudent.financial?.monthlyFee} disabled={isLocked} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg" />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-400 mb-1">Perda Promocional (R$)</label>
              <input type="number" step="0.01" name="promoLoss" defaultValue={selectedStudent.financial?.promoLoss || 0} disabled={isLocked} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg" />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-400 mb-1">Juros Diário (%)</label>
              <input type="number" step="0.01" name="dailyInterest" defaultValue={selectedStudent.financial?.dailyInterest || 0.33} disabled={isLocked} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg" />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-400 mb-1">Multa Rescisória (R$)</label>
              <input type="number" step="0.01" name="fineFee" defaultValue={selectedStudent.financial?.fineFee || 2.00} disabled={isLocked} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg" />
            </div>
          </div>

          <div>
            <label className="block text-xs font-medium text-slate-400 mb-1">Observações</label>
            <textarea name="observations" defaultValue={selectedStudent.financial?.observations} disabled={isLocked} className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg h-24 resize-none" />
          </div>
        </div>

        <div className="p-4 bg-slate-900/50 border-t border-slate-800 flex flex-col sm:flex-row justify-end">
          {!isLocked && (
            <button 
              type="submit"
              disabled={isSaving}
              className="w-full sm:w-auto flex items-center justify-center gap-2 px-6 py-2.5 bg-blue-600 text-white font-bold rounded-lg shadow-lg shadow-blue-500/40 transition-all duration-200 transform hover:-translate-y-1 hover:shadow-2xl hover:shadow-blue-500/30 active:translate-y-0 active:shadow-lg disabled:opacity-50 disabled:pointer-events-none"
            >
              <Save className="w-4 h-4" />
              {isSaving ? 'Salvando...' : 'Salvar e Gerar Parcelas'}
            </button>
          )}
        </div>
      </form>

      {/* Unlock Modal */}
      {showUnlockModal && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-slate-900 rounded-2xl shadow-2xl w-full max-w-sm p-6 border border-slate-700">
            <div className="flex items-center gap-3 mb-4 text-amber-400">
              <Lock className="w-6 h-6" />
              <h3 className="text-lg font-bold">Desbloqueio de Administrador</h3>
            </div>
            <p className="text-sm text-slate-400 mb-4">Insira a senha do administrador para liberar a edição deste cadastro financeiro.</p>
            <input 
              type="password" 
              placeholder="Senha ADM"
              className={cn(
                "w-full px-4 py-2 bg-slate-800 text-white border rounded-lg outline-none mb-4",
                unlockError ? "border-red-500" : "border-slate-200"
              )}
              value={unlockPassword}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => setUnlockPassword(e.target.value)}
            />
            {unlockError && <p className="text-xs text-red-400 mb-4">Senha incorreta</p>}
            <div className="flex gap-2">
              <button 
                onClick={() => setShowUnlockModal(false)}
                className="flex-1 py-2 bg-slate-700 text-slate-300 font-bold rounded-lg hover:bg-slate-600"
              >
                Cancelar
              </button>
              <button 
                onClick={handleUnlock}
                className="flex-1 py-2 bg-blue-600 text-white font-bold rounded-lg"
              >
                Confirmar
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function ParcelasTab({ selectedStudent, setStudents, currentUser, holidays }: { 
  selectedStudent?: Student, 
  setStudents: React.Dispatch<React.SetStateAction<Student[]>>,
  currentUser: AppUser,
  holidays: string[],
}) {
  const [editingParcelaId, setEditingParcelaId] = useState<string | null>(null);
  const [editState, setEditState] = useState<{
    date: string;
    dateBr: string;
    amount: string;
    method: string;
    installments: number;
    baseAmount: number;
    taxaCartaoUnit: number;
  } | null>(null);
  const [overpaymentWarning, setOverpaymentWarning] = useState<{
    installmentId: string;
    data: any;
    total: number;
    newTotalPaid: number;
    excess: number;
    remainingAmount: number;
  } | null>(null);
  const [savingDueId, setSavingDueId] = useState<string | null>(null);

  if (!selectedStudent || !selectedStudent.financial) {
    return (
      <div className="flex flex-col items-center justify-center p-12 bg-slate-900 rounded-xl border border-dashed border-slate-700 text-slate-400">
        <AlertCircle className="w-12 h-12 mb-4 opacity-20" />
        <p className="text-center">Selecione um aluno e preencha o Cadastro Financeiro para ver as parcelas.</p>
      </div>
    );
  }

  const calculateInstallmentValue = (
    installment: Installment,
    referenceDate?: Date,
    referenceIsDateOnly?: boolean,
  ) => {
    const financial = selectedStudent.financial!;
    const dueDate = parseDateOnlyLocal(installment.dueDate);
    const dueLastMoment = lastMomentToPayWithoutLate(dueDate, holidays);

    const targetMoment =
      installment.status === 'Pago' && installment.paymentDate
        ? lastMomentOfCalendarDay(parseDateOnlyLocal(installment.paymentDate))
        : referenceIsDateOnly && referenceDate
          ? lastMomentOfCalendarDay(referenceDate)
          : referenceDate ?? new Date();

    const baseOnTime = financial.monthlyFee;
    const baseLate = financial.promoLoss > 0 ? financial.promoLoss : financial.monthlyFee;

    let total = baseOnTime;
    let isLate = false;
    let daysLate = 0;
    let interestValue = 0;

    if (isAfter(targetMoment, dueLastMoment)) {
      const targetDayStart = startOfDay(targetMoment);
      const firstLateDayStart = startOfDay(addDays(startOfDay(dueLastMoment), 1));
      let current = firstLateDayStart;
      while (isBefore(current, targetDayStart) || isSameDay(current, targetDayStart)) {
        daysLate++;
        current = addDays(current, 1);
      }
      
      if (daysLate > 0) {
        isLate = true;
        interestValue = (financial.dailyInterest || 0) * daysLate;
        total = baseLate + interestValue;
      } else {
        total = baseOnTime;
      }
    }

    return { total, isLate, daysLate, interestValue };
  };

  const handleSaveParcela = async (e: React.FormEvent<HTMLFormElement>, installmentId: string) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    const data = Object.fromEntries(formData.entries());
    const installmentToUpdate = selectedStudent.installments.find(i => i.id === installmentId);

    if (!installmentToUpdate) return;

    const payIso = normalizaDataFormulario(data.paymentDateBr as string);
    if (!payIso) {
      alert('Data de pagamento inválida. Use dd/mm/aaaa.');
      return;
    }
    const method = String(data.paymentMethod || '');
    const nParc = Math.max(1, parseInt(String(data.creditInstallments), 10) || 1);
    const taxaUnit =
      method === 'Cartão de Crédito'
        ? parseFloat(String(data.taxaCartaoUnit ?? '5')) || 0
        : 0;
    const feeTotal = cardFeeTotal(method, nParc, taxaUnit);
    const netNow = parseFloat(String(data.amountPaid));
    if (Number.isNaN(netNow) || netNow < 0) {
      alert('Valor pago inválido.');
      return;
    }

    const dataWithPayDate = {...data, paymentDate: payIso, creditFee: String(feeTotal)};
    const paymentDate = parseDateOnlyLocal(payIso);
    const { total } = calculateInstallmentValue(installmentToUpdate, paymentDate, true);
    const amountPaidNow = netNow;
    const previousAmountPaid = installmentToUpdate.amountPaid || 0;
    const newTotalPaid = previousAmountPaid + amountPaidNow;
    const remainingAmount = total - newTotalPaid;

    if (remainingAmount < -0.01) {
      const excess = Math.abs(remainingAmount);
      setOverpaymentWarning({
        installmentId,
        data: dataWithPayDate,
        total,
        newTotalPaid,
        excess,
        remainingAmount
      });
      return;
    }

    await executeSaveParcela(
      installmentId,
      dataWithPayDate,
      remainingAmount,
      newTotalPaid,
      amountPaidNow,
    );
  };

  const executeSaveParcela = async (installmentId: string, data: any, remainingAmount: number, newTotalPaid: number, amountPaidNow: number) => {
    const isPaidInFull = remainingAmount <= 0.01;

    const updatedInstallments = selectedStudent.installments.map((inst: Installment) => {
      if (inst.id !== installmentId) return inst;

      let newStatus: Installment['status'] = inst.status;
      if (isPaidInFull) {
        newStatus = 'Pago';
      } else if (newTotalPaid > 0) {
        newStatus = 'Pago Parcialmente';
      }

      let newAttendant = inst.attendant || '';
      const paymentDateFormatted = fmtDataBR(data.paymentDate as string);
      const feeSaved = parseFloat(String(data.creditFee || '0')) || 0;
      const actionRecord =
        feeSaved > 0
          ? `${currentUser.username} (parcela R$ ${amountPaidNow.toFixed(2)} + taxa R$ ${feeSaved.toFixed(2)} - ${paymentDateFormatted})`
          : `${currentUser.username} (R$ ${amountPaidNow.toFixed(2)} - ${paymentDateFormatted})`;
      
      if (inst.status === 'Pago Parcialmente' && newAttendant) {
        newAttendant = `${newAttendant} + ${actionRecord}`;
      } else {
        newAttendant = actionRecord;
      }

      return {
        ...inst,
        paymentDate: data.paymentDate as string,
        amountPaid: newTotalPaid,
        remainingAmount: isPaidInFull ? 0 : remainingAmount,
        remainingPaymentDate: !isPaidInFull ? (data.paymentDate as string) : inst.remainingPaymentDate,
        paymentMethod: data.paymentMethod as string,
        creditInstallments: parseInt(data.creditInstallments as string || '1'),
        creditFee: parseFloat(String(data.creditFee || '0')) || 0,
        status: newStatus,
        attendant: newAttendant,
      };
    });

    const studentRef = doc(db, 'students', selectedStudent.id);
    await setDoc(studentRef, { installments: updatedInstallments }, { merge: true });

    setEditingParcelaId(null);
    setEditState(null);
    setOverpaymentWarning(null);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-slate-100">Controle de Parcelas</h2>
          <p className="text-slate-400">Aluno: <span className="font-semibold text-slate-200">{selectedStudent.studentName}</span></p>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4">
        {selectedStudent.installments.map((inst, idx) => {
          const isEditing = editingParcelaId === inst.id;
          const refDate = isEditing && editState?.date ? parseDateOnlyLocal(editState.date) : new Date();
          const refIsDateOnly = !!(isEditing && editState?.date);
          const { total, isLate, daysLate, interestValue } = calculateInstallmentValue(
            inst,
            refDate,
            refIsDateOnly,
          );

          const currentFee =
            isEditing && editState && editState.method === 'Cartão de Crédito'
              ? cardFeeTotal(editState.method, editState.installments, editState.taxaCartaoUnit)
              : 0;
          const displayTotal =
            isEditing && editState?.method === 'Cartão de Crédito' ? total + currentFee : total;

          return (
            <div key={inst.id} className={cn(
              "bg-slate-900 rounded-xl border p-4 transition-all",
              inst.status === 'Pago' ? "border-green-800/50 bg-green-500/10" : 
              inst.status === 'Pago Parcialmente' ? "border-yellow-800/50 bg-yellow-500/10" :
              isLate ? "border-red-800/50 bg-red-500/10" : 
              "border-slate-800"
            )}>
              <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
                <div className="flex flex-col sm:flex-row sm:items-center gap-4 w-full lg:w-auto">
                  <div className="flex items-center justify-between w-full sm:w-auto mb-2 sm:mb-0 border-b border-slate-800/50 pb-3 sm:border-0 sm:pb-0">
                  <div className={cn(
                    "w-10 h-10 rounded-full flex items-center justify-center font-bold text-sm",
                    inst.status === 'Pago' ? "bg-green-500/20 text-green-400" : 
                    isLate ? "bg-red-500/20 text-red-400" : "bg-blue-500/20 text-blue-400"
                  )}>
                    {idx + 1}
                  </div>
                    <span className={cn(
                      "sm:hidden px-3 py-1 rounded-full text-xs font-bold uppercase",
                      inst.status === 'Pago' ? "bg-green-500/20 text-green-300" : inst.status === 'Pago Parcialmente' ? "bg-yellow-500/20 text-yellow-300" : isLate ? "bg-red-500/20 text-red-300" : "bg-blue-500/20 text-blue-300"
                    )}>
                      {inst.status === 'Pago' ? 'Liquidado' : inst.status === 'Pago Parcialmente' ? 'Parcial' : isLate ? 'Atraso' : 'Aberto'}
                    </span>
                  </div>
                  
                  <div className="grid grid-cols-2 sm:flex sm:flex-wrap gap-4 gap-y-2 w-full sm:w-auto">
                  <div>
                    <p className="text-xs font-medium text-slate-400 uppercase">Vencimento</p>
                    <p className="font-bold text-slate-100">{fmtDataBR(inst.dueDate)}</p>
                  </div>
                  <div>
                    <p className="text-xs font-medium text-slate-400 uppercase">Valor</p>
                    <p className={cn("font-bold", isLate && inst.status !== 'Pago' ? "text-red-400" : "text-slate-100")}>R$ {displayTotal.toFixed(2)}</p>
                  </div>
                  {isLate && inst.status !== 'Pago' && (
                    <>
                      <div>
                        <p className="text-xs font-medium text-red-400 uppercase">Dias Atraso</p>
                        <p className="font-bold text-red-400">{daysLate} dias</p>
                      </div>
                      <div>
                        <p className="text-xs font-medium text-red-400 uppercase">Juros Diário</p>
                        <p className="font-bold text-red-400">R$ {interestValue.toFixed(2)}</p>
                      </div>
                    </>
                  )}
                  {inst.status === 'Pago' && (
                    <>
                      <div>
                        <p className="text-xs font-medium text-slate-400 uppercase">Pago em</p>
                        <p className="font-bold text-green-400">{fmtDataBR(inst.paymentDate!)}</p>
                      </div>
                      <div>
                        <p className="text-xs font-medium text-slate-400 uppercase">Valor Pago</p>
                        <p className="font-bold text-green-400">R$ {inst.amountPaid?.toFixed(2)}</p>
                      </div>
                      <div className="w-full sm:w-auto col-span-2">
                        <p className="text-xs font-medium text-slate-400 uppercase">Recebido por</p>
                        <p className="font-bold text-slate-300 text-xs break-words" title={inst.attendant}>{inst.attendant}</p>
                      </div>
                      <div className="w-full sm:w-auto col-span-2">
                        <p className="text-xs font-medium text-slate-400 uppercase">Forma de pagamento</p>
                        <p className="font-bold text-slate-300 text-sm">
                          {inst.paymentMethod?.trim() ? inst.paymentMethod : '—'}
                        </p>
                      </div>
                    </>
                  )}
                  {inst.status === 'Pago Parcialmente' && (
                    <>
                      <div>
                        <p className="text-xs font-medium text-slate-400 uppercase">Total Pago</p>
                        <p className="font-bold text-yellow-400">R$ {inst.amountPaid?.toFixed(2)}</p>
                      </div>
                      <div>
                        <p className="text-xs font-medium text-slate-400 uppercase">Restante</p>
                        <p className="font-bold text-yellow-400">R$ {Math.max(0, total - (inst.amountPaid || 0)).toFixed(2)}</p>
                      </div>
                      <div className="w-full sm:w-auto col-span-2">
                        <p className="text-xs font-medium text-slate-400 uppercase">Recebido por</p>
                        <p className="font-bold text-slate-300 text-xs break-words" title={inst.attendant}>{inst.attendant}</p>
                      </div>
                      <div className="w-full sm:w-auto col-span-2">
                        <p className="text-xs font-medium text-slate-400 uppercase">Forma de pagamento</p>
                        <p className="font-bold text-slate-300 text-sm">
                          {inst.paymentMethod?.trim() ? inst.paymentMethod : '—'}
                        </p>
                      </div>
                    </>
                  )}
                  </div>
                </div>

                <div className="flex items-center justify-between sm:justify-end gap-3 w-full lg:w-auto border-t border-slate-800 lg:border-0 pt-4 lg:pt-0 mt-2 lg:mt-0">
                  <span className={cn(
                    "hidden sm:inline-block px-3 py-1 rounded-full text-xs font-bold uppercase",
                    inst.status === 'Pago' ? "bg-green-500/20 text-green-300" : inst.status === 'Pago Parcialmente' ? "bg-yellow-500/20 text-yellow-300" : isLate ? "bg-red-500/20 text-red-300" : "bg-blue-500/20 text-blue-300"
                  )}>
                    {inst.status === 'Pago' ? 'Liquidado' : inst.status === 'Pago Parcialmente' ? 'Parcial' : isLate ? `Atrasado (${daysLate} dias)` : 'Em Aberto'}
                  </span>
                  {inst.status !== 'Pago' && !isEditing && (
                    <button 
                      onClick={() => {
                        setEditingParcelaId(inst.id);
                        const todayStr = format(new Date(), 'yyyy-MM-dd');
                        const { total: initialTotal } = calculateInstallmentValue(
                          inst,
                          parseDateOnlyLocal(todayStr),
                          true,
                        );
                        const baseRemaining = initialTotal - (inst.amountPaid || 0);
                        setEditState({
                          date: todayStr,
                          dateBr: fmtDataBR(todayStr),
                          amount: baseRemaining.toFixed(2),
                          method: 'Dinheiro',
                          installments: 1,
                          baseAmount: baseRemaining,
                          taxaCartaoUnit: 5,
                        });
                      }}
                      className="w-full sm:w-auto px-4 py-2 bg-blue-600 text-white text-sm font-bold rounded-lg hover:bg-blue-500 active:bg-blue-700 transition-colors"
                    >
                      Baixar Parcela
                    </button>
                  )}
                </div>
              </div>

              {currentUser.role === 'Administrador' && inst.status !== 'Pago' && (
                <div className="mt-3 rounded-lg border border-amber-900/40 bg-amber-950/20 px-3 py-2">
                  <p className="text-[11px] text-amber-200/90 mb-2 leading-snug">
                    <span className="font-bold text-amber-400">Regra de vencimento:</span> vence em{' '}
                    <strong>dia útil</strong> → sem juros até <strong>23:59:59</strong> desse dia. Vence em{' '}
                    <strong>sábado, domingo ou feriado nacional</strong> → sem juros até o fim do{' '}
                    <strong>primeiro dia útil</strong> seguinte (ex.: domingo → segunda). Na <strong>data de pagamento</strong>{' '}
                    (só dia) vale até o fim desse dia civil. Depois do prazo: juros por <strong>dia corrido</strong>.
                  </p>
                  <form
                    key={`due-adj-${inst.id}-${inst.dueDate}`}
                    className="flex flex-wrap items-end gap-2"
                    onSubmit={async (ev) => {
                      ev.preventDefault();
                      const fd = new FormData(ev.currentTarget);
                      const br = String(fd.get('dueBrAdj') || '');
                      const iso = inputBRParaIso(br);
                      if (!iso) {
                        alert('Data inválida. Use dd/mm/aaaa.');
                        return;
                      }
                      setSavingDueId(inst.id);
                      try {
                        const updated = selectedStudent.installments.map((i: Installment) =>
                          i.id === inst.id ? {...i, dueDate: iso} : i,
                        );
                        await setDoc(
                          doc(db, 'students', selectedStudent.id),
                          {installments: updated},
                          {merge: true},
                        );
                      } catch (err) {
                        console.error(err);
                        alert('Não foi possível salvar o vencimento.');
                      } finally {
                        setSavingDueId(null);
                      }
                    }}
                  >
                    <div className="flex-1 min-w-[168px]">
                      <label className="block text-[10px] uppercase tracking-wide text-slate-500 mb-0.5">
                        Novo vencimento
                      </label>
                      <input
                        name="dueBrAdj"
                        type="text"
                        inputMode="numeric"
                        placeholder="dd/mm/aaaa"
                        defaultValue={fmtDataBR(inst.dueDate)}
                        onChange={(e) => {
                          e.target.value = maskDataBR(e.target.value);
                        }}
                        maxLength={10}
                        className="w-full px-2 py-1.5 bg-slate-900 border border-slate-600 rounded text-sm text-white"
                      />
                    </div>
                    <button
                      type="submit"
                      disabled={savingDueId === inst.id}
                      className="px-3 py-1.5 bg-amber-600 text-white text-xs font-bold rounded hover:bg-amber-500 disabled:opacity-50"
                    >
                      {savingDueId === inst.id ? 'Salvando…' : 'Aplicar vencimento'}
                    </button>
                  </form>
                </div>
              )}

              {isEditing && (
                <form onSubmit={(e: React.FormEvent<HTMLFormElement>) => handleSaveParcela(e, inst.id)} className="mt-4 pt-4 border-t border-slate-800 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-5 gap-4">
                  <div>
                    <label className="block text-xs font-medium text-slate-400 mb-1">Data de Pagamento</label>
                    <input
                      type="text"
                      inputMode="numeric"
                      name="paymentDateBr"
                      placeholder="dd/mm/aaaa"
                      autoComplete="off"
                      value={editState?.dateBr ?? ''}
                      onChange={(e) => {
                        const br = maskDataBR(e.target.value);
                        setEditState(prev => {
                          if (!prev) return null;
                          const iso = inputBRParaIso(br);
                          if (iso) {
                            const {total: newTotal} = calculateInstallmentValue(
                              inst,
                              parseDateOnlyLocal(iso),
                              true,
                            );
                            const newBase = newTotal - (inst.amountPaid || 0);
                            return {
                              ...prev,
                              date: iso,
                              dateBr: br,
                              baseAmount: newBase,
                              amount: newBase.toFixed(2),
                            };
                          }
                          return {...prev, dateBr: br};
                        });
                      }}
                      required
                      maxLength={10}
                      className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-slate-400 mb-1">
                      {editState?.method === 'Cartão de Crédito'
                        ? 'Valor pago — parcela (R$, sem taxa)'
                        : 'Valor pago (R$)'}
                    </label>
                    <input 
                      type="number" step="0.01" name="amountPaid" 
                      value={editState?.amount || ''}
                      onChange={(e) => setEditState(prev => prev ? { ...prev, amount: e.target.value } : null)}
                      required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg" 
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-slate-400 mb-1">Forma de Pagamento</label>
                    <select 
                      name="paymentMethod" 
                      value={editState?.method || 'Dinheiro'}
                      onChange={(e) => {
                        const newMethod = e.target.value;
                        setEditState(prev => {
                          if (!prev) return null;
                          return {
                            ...prev,
                            method: newMethod,
                            amount: prev.baseAmount.toFixed(2),
                          };
                        });
                      }}
                      required 
                      className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg"
                    >
                      <option value="Dinheiro">Dinheiro</option>
                      <option value="PIX">PIX</option>
                      <option value="Cartão de Débito">Cartão de Débito</option>
                      <option value="Cartão de Crédito">Cartão de Crédito</option>
                      <option value="Transferência">Transferência</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-slate-400 mb-1">Parcelas (Crédito)</label>
                    <input 
                      type="number" min="1" name="creditInstallments" 
                      value={editState?.installments || 1}
                      onChange={(e) => {
                        const newInst = Math.max(1, parseInt(e.target.value, 10) || 1);
                        setEditState(prev => (prev ? {...prev, installments: newInst} : null));
                      }}
                      className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg" 
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-slate-400 mb-1">Taxa cartão (R$ / parcela)</label>
                    <input
                      type="number"
                      step="0.01"
                      min="0"
                      name="taxaCartaoUnit"
                      value={editState?.method === 'Cartão de Crédito' ? editState.taxaCartaoUnit : 0}
                      disabled={editState?.method !== 'Cartão de Crédito'}
                      onChange={(e) => {
                        const v = parseFloat(e.target.value);
                        setEditState(prev =>
                          prev
                            ? {...prev, taxaCartaoUnit: Number.isFinite(v) && v >= 0 ? v : 0}
                            : null,
                        );
                      }}
                      className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg disabled:opacity-50 disabled:cursor-not-allowed"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-slate-400 mb-1">Total taxas (R$)</label>
                    <input
                      type="text"
                      readOnly
                      value={
                        editState?.method === 'Cartão de Crédito'
                          ? cardFeeTotal(
                              editState.method,
                              editState.installments,
                              editState.taxaCartaoUnit,
                            ).toFixed(2)
                          : '0.00'
                      }
                      className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-slate-400 rounded-lg cursor-not-allowed outline-none"
                    />
                  </div>
                  {editState?.method === 'Cartão de Crédito' && (
                    <div className="sm:col-span-2 md:col-span-5 rounded-lg border border-slate-700 bg-slate-800/50 px-3 py-2 text-sm">
                      <span className="text-slate-400">Total da baixa (parcela + taxas): </span>
                      <span className="font-bold text-emerald-400">
                        R${' '}
                        {(
                          (parseFloat(editState.amount) || 0) +
                          cardFeeTotal(
                            editState.method,
                            editState.installments,
                            editState.taxaCartaoUnit,
                          )
                        ).toFixed(2)}
                      </span>
                    </div>
                  )}
                  <div className="flex flex-col sm:flex-row items-end gap-2 sm:col-span-2 md:col-span-5">
                    <button type="submit" className="flex-1 py-2 bg-green-600 text-white font-bold rounded-lg hover:bg-green-700">
                      Confirmar
                    </button>
                    <button type="button" onClick={() => { setEditingParcelaId(null); setEditState(null); }} className="flex-1 py-2 bg-slate-700 text-slate-300 font-bold rounded-lg hover:bg-slate-600">
                      Cancelar
                    </button>
                  </div>
                </form>
              )}
            </div>
          );
        })}
      </div>

      {/* Modal de Aviso de Valor Excedente */}
      {overpaymentWarning && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-slate-900 rounded-2xl shadow-2xl w-full max-w-md p-6 border border-slate-700">
            <div className="flex items-center gap-3 mb-4 text-amber-500">
              <AlertCircle className="w-6 h-6" />
              <h3 className="text-lg font-bold">Aviso de Valor Excedente</h3>
            </div>
            <p className="text-sm text-slate-400 mb-4">
              O valor inserido ultrapassa o total da parcela!
            </p>
            <div className="bg-slate-800 p-4 rounded-lg mb-6 space-y-2 border border-slate-700/50">
              <div className="flex justify-between text-sm">
                <span className="text-slate-400">Valor cobrado:</span>
                <span className="font-bold text-slate-200">R$ {overpaymentWarning.total.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-slate-400">Total que ficará pago:</span>
                <span className="font-bold text-amber-400">R$ {overpaymentWarning.newTotalPaid.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-sm border-t border-slate-700 pt-2 mt-2">
                <span className="text-slate-400">Valor a mais:</span>
                <span className="font-bold text-amber-500">R$ {overpaymentWarning.excess.toFixed(2)}</span>
              </div>
            </div>
            <p className="text-sm text-slate-400 mb-6">
              Deseja prosseguir e registrar esse pagamento excedente?
            </p>
            <div className="flex gap-3">
              <button 
                onClick={() => setOverpaymentWarning(null)}
                className="flex-1 py-2.5 bg-slate-800 text-slate-300 font-bold rounded-lg hover:bg-slate-700 transition-colors"
              >
                Cancelar
              </button>
              <button 
                onClick={() => executeSaveParcela(overpaymentWarning.installmentId, overpaymentWarning.data, overpaymentWarning.remainingAmount, overpaymentWarning.newTotalPaid, parseFloat(overpaymentWarning.data.amountPaid as string))}
                className="flex-1 py-2.5 bg-amber-600 text-white font-bold rounded-lg hover:bg-amber-500 transition-colors"
              >
                Sim, Prosseguir
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function RelatoriosTab({ students, currentUser, holidays }: { students: Student[], currentUser: AppUser, holidays: string[] }) {
  const [reportType, setReportType] = useState<'debitos' | 'aniversariantes' | 'em_dia' | 'pagantes'>('debitos');
  const startInit = format(startOfMonth(new Date()), 'yyyy-MM-dd');
  const endInit = format(endOfMonth(new Date()), 'yyyy-MM-dd');
  const [startDate, setStartDate] = useState(startInit);
  const [endDate, setEndDate] = useState(endInit);
  const [startDateBr, setStartDateBr] = useState(() => fmtDataBR(startInit));
  const [endDateBr, setEndDateBr] = useState(() => fmtDataBR(endInit));
  const [debtorSearch, setDebtorSearch] = useState('');
  const [debtorFilter, setDebtorFilter] = useState<'all' | 'month' | '3months'>('all');
  const [debtorPage, setDebtorPage] = useState(1);

  const exportPDF = (title: string, data: any[], columns: string[]) => {
    if (data.length === 0) {
      alert('Não há dados para exportar neste período.');
      return;
    }

    const doc = new jsPDF();
    doc.text(title, 14, 15);
    doc.setFontSize(10);
    doc.text(`Gerado por: ${currentUser.username} em ${fmtDataHoraBR(new Date())}`, 14, 22);
    
    autoTable(doc, {
      startY: 30,
      head: [columns],
      body: data,
      theme: 'grid',
      headStyles: { fillColor: [37, 99, 235] }
    });
    
    doc.save(`${title.toLowerCase().replace(/\s/g, '_')}.pdf`);
  };

  const getDebtors = () => {
    const debtors: any[] = [];
    const now = new Date();

    students.forEach(s => {
      s.installments.forEach((inst, idx) => {
        const dueDate = parseDateOnlyLocal(inst.dueDate);
        const dueLastMoment = lastMomentToPayWithoutLate(dueDate, holidays);
        if (inst.status !== 'Pago' && isAfter(now, dueLastMoment)) {
          let daysLate = 0;
          const todayStart = startOfDay(now);
          const firstLateDayStart = startOfDay(addDays(startOfDay(dueLastMoment), 1));
          let current = firstLateDayStart;
          while (isBefore(current, todayStart) || isSameDay(current, todayStart)) {
            daysLate++;
            current = addDays(current, 1);
          }

          if (daysLate > 0) {
            let valorAberto = 0;
            if (s.financial) {
              const amountPaid = inst.amountPaid || 0;
              const baseLate = s.financial.promoLoss > 0 ? s.financial.promoLoss : s.financial.monthlyFee;
              const interest = s.financial.dailyInterest * daysLate;
              const total = baseLate + interest;
              valorAberto = total - amountPaid;
            }

            debtors.push({
              aluno: s.studentName,
              responsavel: s.guardianName,
              parcela: idx + 1,
              vencimento: fmtDataBR(dueDate),
              atraso: `${daysLate} dias`,
              valor: `R$ ${valorAberto.toFixed(2)}`,
              telefone: s.phone,
              rawDueDate: dueDate
            });
          }
        }
      });
    });
    return debtors;
  };

  const getBirthdays = () => {
    const currentMonth = new Date().getMonth();
    return students
      .filter(s => parseDateOnlyLocal(s.studentBirthDate).getMonth() === currentMonth)
      .map(s => ({
        nome: s.studentName,
        data: fmtDataBR(s.studentBirthDate),
        turmas: s.financial?.coursePackage || 'N/A',
        horarioTech: s.techClassTime || '-',
        horarioEng: s.englishClassTime || '-'
      }));
  };

  const getOnTime = () => {
    const results: any[] = [];
    const start = parseDateOnlyLocal(startDate);
    const end = parseDateOnlyLocal(endDate);
    end.setHours(23, 59, 59, 999);

    students.forEach(s => {
      s.installments.forEach((inst, idx) => {
        if (inst.status === 'Pago' && inst.paymentDate) {
          const pDate = parseDateOnlyLocal(inst.paymentDate);
          const dDate = parseDateOnlyLocal(inst.dueDate);
          if ((isAfter(pDate, start) || isSameDay(pDate, start)) && (isBefore(pDate, end) || isSameDay(pDate, end))) {
            if (!isAfter(pDate, dDate)) {
              results.push({
                aluno: s.studentName,
                responsavel: s.guardianName,
                parcela: `${idx + 1}ª`,
                vencimento: fmtDataBR(dDate),
                pagamento: fmtDataBR(pDate),
                valor: `R$ ${inst.amountPaid?.toFixed(2)}`,
                atendente: inst.attendant || 'Sistema'
              });
            }
          }
        }
      });
    });
    return results;
  };

  const getAllPayments = () => {
    const results: any[] = [];
    const start = parseDateOnlyLocal(startDate);
    const end = parseDateOnlyLocal(endDate);
    end.setHours(23, 59, 59, 999);

    students.forEach(s => {
      s.installments.forEach((inst, idx) => {
        if ((inst.status === 'Pago' || inst.status === 'Pago Parcialmente') && inst.paymentDate) {
          const pDate = parseDateOnlyLocal(inst.paymentDate);
          if ((isAfter(pDate, start) || isSameDay(pDate, start)) && (isBefore(pDate, end) || isSameDay(pDate, end))) {
            results.push({
              aluno: s.studentName,
              responsavel: s.guardianName,
              parcela: `${idx + 1}ª`,
              vencimento: fmtDataBR(inst.dueDate),
              pagamento: fmtDataBR(pDate),
              valor: `R$ ${inst.amountPaid?.toFixed(2)}`,
              atendente: inst.attendant || 'Sistema'
            });
          }
        }
      });
    });
    return results;
  };

  const allDebtors = getDebtors();
  const filteredDebtors = allDebtors.filter(d => {
    const matchSearch = d.aluno.toLowerCase().includes(debtorSearch.toLowerCase()) || d.responsavel.toLowerCase().includes(debtorSearch.toLowerCase());
    if (!matchSearch) return false;
    
    const today = new Date();
    if (debtorFilter === 'month') return isSameMonth(d.rawDueDate, today);
    if (debtorFilter === '3months') return isAfter(d.rawDueDate, addMonths(today, -3));
    return true;
  });

  const DEBTORS_PER_PAGE = 20;
  const totalDebtorPages = Math.ceil(filteredDebtors.length / DEBTORS_PER_PAGE) || 1;
  const paginatedDebtors = filteredDebtors.slice((debtorPage - 1) * DEBTORS_PER_PAGE, debtorPage * DEBTORS_PER_PAGE);

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-slate-100">Relatórios Gerenciais</h2>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <ReportCard 
          active={reportType === 'debitos'} 
          onClick={() => setReportType('debitos')} 
          label="Alunos em Débito" 
          icon={<AlertCircle className="w-5 h-5" />}
        />
        <ReportCard 
          active={reportType === 'aniversariantes'} 
          onClick={() => setReportType('aniversariantes')} 
          label="Aniversariantes" 
          icon={<Calendar className="w-5 h-5" />}
        />
        {currentUser.role === 'Administrador' && (
          <ReportCard 
            active={reportType === 'em_dia'} 
            onClick={() => setReportType('em_dia')} 
            label="Alunos em Dia" 
            icon={<CheckCircle2 className="w-5 h-5" />}
          />
        )}
        {currentUser.role === 'Administrador' && (
          <ReportCard 
            active={reportType === 'pagantes'} 
            onClick={() => setReportType('pagantes')} 
            label="Geral Pagantes" 
            icon={<DollarSign className="w-5 h-5" />}
          />
        )}
      </div>

      <div className="bg-slate-900 rounded-xl border border-slate-800 p-6">
        {reportType === 'debitos' && (
          <div className="space-y-4">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
              <h3 className="font-bold text-slate-200 whitespace-nowrap">Lista de Inadimplentes</h3>
              
              <div className="flex-1 w-full max-w-md relative">
                <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                <input 
                  type="text" 
                  placeholder="Buscar por aluno ou responsável..." 
                  value={debtorSearch}
                  onChange={(e) => { setDebtorSearch(e.target.value); setDebtorPage(1); }}
                  className="w-full pl-9 pr-4 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg text-sm outline-none focus:border-blue-500"
                />
              </div>

              <button 
                onClick={() => exportPDF('Relatório de Débitos', filteredDebtors.map(d => [d.aluno, d.responsavel, d.parcela + 'ª', d.vencimento, d.atraso, d.valor, d.telefone]), ['Aluno', 'Responsável', 'Parcela', 'Vencimento', 'Atraso', 'Valor Aberto', 'Telefone'])}
                className="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white rounded-lg text-sm font-bold transition-colors w-full md:w-auto"
              >
                <Download className="w-4 h-4" /> Exportar PDF
              </button>
            </div>

            <div className="flex gap-2 pb-2 overflow-x-auto snap-x">
              <button onClick={() => { setDebtorFilter('all'); setDebtorPage(1); }} className={cn("snap-start px-3 py-1.5 rounded-lg text-xs font-bold whitespace-nowrap transition-colors", debtorFilter === 'all' ? "bg-blue-600 text-white" : "bg-slate-800 text-slate-400 hover:bg-slate-700")}>Todos em atraso</button>
              <button onClick={() => { setDebtorFilter('month'); setDebtorPage(1); }} className={cn("snap-start px-3 py-1.5 rounded-lg text-xs font-bold whitespace-nowrap transition-colors", debtorFilter === 'month' ? "bg-blue-600 text-white" : "bg-slate-800 text-slate-400 hover:bg-slate-700")}>Atrasados neste mês</button>
              <button onClick={() => { setDebtorFilter('3months'); setDebtorPage(1); }} className={cn("snap-start px-3 py-1.5 rounded-lg text-xs font-bold whitespace-nowrap transition-colors", debtorFilter === '3months' ? "bg-blue-600 text-white" : "bg-slate-800 text-slate-400 hover:bg-slate-700")}>Últimos 3 meses</button>
            </div>

            <div className="overflow-x-auto border border-slate-800 rounded-lg">
              <table className="w-full text-sm text-left">
                <thead className="bg-slate-800 text-slate-400 uppercase text-xs font-bold">
                  <tr>
                    <th className="px-4 py-3">Aluno</th>
                    <th className="px-4 py-3">Parcela</th>
                    <th className="px-4 py-3">Vencimento</th>
                    <th className="px-4 py-3">Atraso</th>
                    <th className="px-4 py-3">Valor Aberto</th>
                    <th className="px-4 py-3">Telefone</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800">
                  {paginatedDebtors.length > 0 ? paginatedDebtors.map((d, i) => (
                    <tr key={i}>
                      <td className="px-4 py-3 font-medium text-slate-200">
                        {d.aluno}
                        <div className="text-xs text-slate-500 font-normal mt-0.5">Resp: {d.responsavel}</div>
                      </td>
                      <td className="px-4 py-3">{d.parcela}ª</td>
                      <td className="px-4 py-3">{d.vencimento}</td>
                      <td className="px-4 py-3 text-red-500 font-bold">{d.atraso}</td>
                      <td className="px-4 py-3 text-red-400 font-bold">{d.valor}</td>
                      <td className="px-4 py-3 text-slate-300">{d.telefone}</td>
                    </tr>
                  )) : (
                    <tr>
                      <td colSpan={6} className="px-4 py-8 text-center text-slate-500">Nenhum devedor encontrado com estes filtros.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            {/* Controles de Paginação */}
            {totalDebtorPages > 1 && (
              <div className="flex items-center justify-center gap-1 mt-4">
                <button onClick={() => setDebtorPage(p => Math.max(1, p - 1))} disabled={debtorPage === 1} className="px-3 py-1 rounded-lg bg-slate-800 text-slate-300 hover:bg-slate-700 disabled:opacity-50 disabled:pointer-events-none text-sm font-bold transition-colors">
                  Anterior
                </button>
                {Array.from({ length: totalDebtorPages }).map((_, i) => (
                  <button key={i} onClick={() => setDebtorPage(i + 1)} className={cn("w-8 h-8 rounded-lg text-sm font-bold flex items-center justify-center transition-colors", debtorPage === i + 1 ? "bg-blue-600 text-white" : "bg-slate-800 text-slate-300 hover:bg-slate-700")}>
                    {i + 1}
                  </button>
                ))}
                <button onClick={() => setDebtorPage(p => Math.min(totalDebtorPages, p + 1))} disabled={debtorPage === totalDebtorPages} className="px-3 py-1 rounded-lg bg-slate-800 text-slate-300 hover:bg-slate-700 disabled:opacity-50 disabled:pointer-events-none text-sm font-bold transition-colors">
                  Próximo
                </button>
              </div>
            )}
          </div>
        )}

        {reportType === 'aniversariantes' && (
          <div className="space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <h3 className="font-bold text-slate-200">Aniversariantes do Mês</h3>
              <button 
                onClick={() => exportPDF('Aniversariantes do Mês', getBirthdays().map(b => Object.values(b)), ['Nome', 'Data', 'Turmas', 'Horário Tec.', 'Horário Ing.'])}
                className="w-full sm:w-auto flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white rounded-lg text-sm font-bold transition-colors"
              >
                <Download className="w-4 h-4" /> Exportar PDF
              </button>
            </div>
            <div className="overflow-x-auto border border-slate-800 rounded-lg">
              <table className="w-full text-sm text-left">
                <thead className="bg-slate-800 text-slate-400 uppercase text-xs font-bold">
                  <tr>
                    <th className="px-4 py-3">Aniversariante</th>
                    <th className="px-4 py-3">Data</th>
                    <th className="px-4 py-3">Turmas</th>
                    <th className="px-4 py-3">Horário Tec.</th>
                    <th className="px-4 py-3">Horário Ing.</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800">
                  {getBirthdays().length > 0 ? getBirthdays().map((b, i) => (
                    <tr key={i}>
                      <td className="px-4 py-3 font-medium text-slate-200">{b.nome}</td>
                      <td className="px-4 py-3 font-bold text-blue-500">{b.data}</td>
                      <td className="px-4 py-3 text-slate-300">{b.turmas}</td>
                      <td className="px-4 py-3 text-slate-300">{b.horarioTech}</td>
                      <td className="px-4 py-3 text-slate-300">{b.horarioEng}</td>
                    </tr>
                  )) : (
                    <tr>
                      <td colSpan={5} className="px-4 py-8 text-center text-slate-500">Nenhum aniversariante neste mês.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {reportType === 'em_dia' && (
          <div className="space-y-4">
            <div className="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
              <h3 className="font-bold text-slate-200">Pagamentos em Dia</h3>
              <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2 w-full lg:w-auto">
                <div className="flex items-center gap-2 w-full sm:w-auto">
                  <input
                    type="text"
                    inputMode="numeric"
                    placeholder="dd/mm/aaaa"
                    value={startDateBr}
                    onChange={(e) => {
                      const br = maskDataBR(e.target.value);
                      setStartDateBr(br);
                      const iso = inputBRParaIso(br);
                      if (iso) setStartDate(iso);
                    }}
                    maxLength={10}
                    className="w-full sm:w-auto px-3 py-2 border border-slate-700 bg-slate-800 text-slate-300 rounded-lg text-sm outline-none focus:border-blue-500"
                  />
                  <span className="hidden sm:inline text-slate-400 text-sm">até</span>
                  <input
                    type="text"
                    inputMode="numeric"
                    placeholder="dd/mm/aaaa"
                    value={endDateBr}
                    onChange={(e) => {
                      const br = maskDataBR(e.target.value);
                      setEndDateBr(br);
                      const iso = inputBRParaIso(br);
                      if (iso) setEndDate(iso);
                    }}
                    maxLength={10}
                    className="w-full sm:w-auto px-3 py-2 border border-slate-700 bg-slate-800 text-slate-300 rounded-lg text-sm outline-none focus:border-blue-500"
                  />
                </div>
                <button 
                  onClick={() => exportPDF(`Pagamentos em Dia (${fmtDataBR(startDate)} a ${fmtDataBR(endDate)})`, getOnTime().map(o => [o.aluno, o.responsavel, o.parcela, o.vencimento, o.pagamento, o.valor, o.atendente]), ['Aluno', 'Responsável', 'Parcela', 'Vencimento', 'Pagamento', 'Valor Pago', 'Atendente'])}
                  className="w-full sm:w-auto flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white rounded-lg text-sm font-bold transition-colors mt-2 sm:mt-0"
                >
                  <Download className="w-4 h-4" /> PDF
                </button>
              </div>
            </div>
            <div className="overflow-x-auto border border-slate-800 rounded-lg">
              <table className="w-full text-sm text-left">
                <thead className="bg-slate-800 text-slate-400 uppercase text-xs font-bold">
                  <tr>
                    <th className="px-4 py-3 whitespace-nowrap">Aluno</th>
                  <th className="px-4 py-3 whitespace-nowrap">Parcela</th>
                    <th className="px-4 py-3 whitespace-nowrap">Vencimento</th>
                    <th className="px-4 py-3 whitespace-nowrap">Pagamento</th>
                    <th className="px-4 py-3 whitespace-nowrap">Valor Pago</th>
                  <th className="px-4 py-3 whitespace-nowrap">Atendente</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800">
                  {getOnTime().length > 0 ? getOnTime().map((o, i) => (
                    <tr key={i}>
                      <td className="px-4 py-3 font-medium text-slate-200 whitespace-nowrap">
                        {o.aluno}
                        <div className="text-xs text-slate-500 font-normal mt-0.5">Resp: {o.responsavel}</div>
                      </td>
                    <td className="px-4 py-3 whitespace-nowrap">{o.parcela}</td>
                      <td className="px-4 py-3 whitespace-nowrap">{o.vencimento}</td>
                      <td className="px-4 py-3 text-green-600 font-bold whitespace-nowrap">{o.pagamento}</td>
                      <td className="px-4 py-3 whitespace-nowrap">{o.valor}</td>
                    <td className="px-4 py-3 whitespace-nowrap">{o.atendente}</td>
                    </tr>
                  )) : (
                    <tr>
                    <td colSpan={6} className="px-4 py-8 text-center text-slate-500">Nenhum pagamento em dia encontrado neste período.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {reportType === 'pagantes' && (
          <div className="space-y-4">
            <div className="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
              <h3 className="font-bold text-slate-200">Geral de Pagamentos</h3>
              <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2 w-full lg:w-auto">
                <div className="flex items-center gap-2 w-full sm:w-auto">
                  <input
                    type="text"
                    inputMode="numeric"
                    placeholder="dd/mm/aaaa"
                    value={startDateBr}
                    onChange={(e) => {
                      const br = maskDataBR(e.target.value);
                      setStartDateBr(br);
                      const iso = inputBRParaIso(br);
                      if (iso) setStartDate(iso);
                    }}
                    maxLength={10}
                    className="w-full sm:w-auto px-3 py-2 border border-slate-700 bg-slate-800 text-slate-300 rounded-lg text-sm outline-none focus:border-blue-500"
                  />
                  <span className="hidden sm:inline text-slate-400 text-sm">até</span>
                  <input
                    type="text"
                    inputMode="numeric"
                    placeholder="dd/mm/aaaa"
                    value={endDateBr}
                    onChange={(e) => {
                      const br = maskDataBR(e.target.value);
                      setEndDateBr(br);
                      const iso = inputBRParaIso(br);
                      if (iso) setEndDate(iso);
                    }}
                    maxLength={10}
                    className="w-full sm:w-auto px-3 py-2 border border-slate-700 bg-slate-800 text-slate-300 rounded-lg text-sm outline-none focus:border-blue-500"
                  />
                </div>
                <button 
                  onClick={() => exportPDF(`Geral de Pagamentos (${fmtDataBR(startDate)} a ${fmtDataBR(endDate)})`, getAllPayments().map(p => [p.aluno, p.responsavel, p.parcela, p.vencimento, p.pagamento, p.valor, p.atendente]), ['Aluno', 'Responsável', 'Parcela', 'Vencimento', 'Pagamento', 'Valor Pago', 'Atendente'])}
                  className="w-full sm:w-auto flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white rounded-lg text-sm font-bold transition-colors mt-2 sm:mt-0"
                >
                  <Download className="w-4 h-4" /> PDF
                </button>
              </div>
            </div>
            <div className="overflow-x-auto border border-slate-800 rounded-lg">
              <table className="w-full text-sm text-left">
                <thead className="bg-slate-800 text-slate-400 uppercase text-xs font-bold">
                  <tr>
                    <th className="px-4 py-3">Aluno</th>
                    <th className="px-4 py-3">Parcela</th>
                    <th className="px-4 py-3">Vencimento</th>
                    <th className="px-4 py-3">Pagamento</th>
                    <th className="px-4 py-3">Valor Pago</th>
                    <th className="px-4 py-3">Atendente</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800">
                  {getAllPayments().length > 0 ? getAllPayments().map((p, i) => (
                    <tr key={i}>
                      <td className="px-4 py-3 font-medium text-slate-200">
                        {p.aluno}
                        <div className="text-xs text-slate-500 font-normal mt-0.5">Resp: {p.responsavel}</div>
                      </td>
                      <td className="px-4 py-3">{p.parcela}</td>
                      <td className="px-4 py-3">{p.vencimento}</td>
                      <td className="px-4 py-3">{p.pagamento}</td>
                      <td className="px-4 py-3 font-bold text-blue-600">{p.valor}</td>
                      <td className="px-4 py-3 text-slate-300">{p.atendente}</td>
                    </tr>
                  )) : (
                    <tr>
                      <td colSpan={6} className="px-4 py-8 text-center text-slate-500">Nenhum pagamento encontrado neste período.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function UsuariosTab() {
  const [users, setUsers] = useState<AppUser[]>([]);
  const [isSaving, setIsSaving] = useState(false);
  const [editingUser, setEditingUser] = useState<AppUser | null>(null);
  const [userToToggle, setUserToToggle] = useState<AppUser | null>(null);
  const [userToDelete, setUserToDelete] = useState<AppUser | null>(null);
  const [feedbackMsg, setFeedbackMsg] = useState<{type: 'error'|'success', text: string} | null>(null);

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'users'), (snapshot) => {
      setUsers(snapshot.docs.map(doc => ({ ...doc.data(), id: doc.id } as AppUser)));
    });
    return () => unsub();
  }, []);

  const handleCreateUser = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setFeedbackMsg(null);
    const form = e.currentTarget;
    setIsSaving(true);
    const formData = new FormData(form);
    const newUser = {
      username: formData.get('username') as string,
      password: formData.get('password') as string,
      role: formData.get('role') as 'Administrador' | 'Colaborador',
      isActive: true
    };

    try {
      const q = query(collection(db, 'users'), where('username', '==', newUser.username));
      const snap = await getDocs(q);
      if (!snap.empty) {
        setFeedbackMsg({ type: 'error', text: 'Já existe um usuário com este nome.' });
        return;
      }

      await setDoc(doc(collection(db, 'users')), newUser);
      form.reset();
      setFeedbackMsg({ type: 'success', text: 'Usuário criado com sucesso!' });
      setTimeout(() => setFeedbackMsg(null), 3000);
    } catch (error) {
      console.error(error);
      setFeedbackMsg({ type: 'error', text: 'Erro ao criar usuário.' });
    } finally {
      setIsSaving(false);
    }
  };

  const confirmToggleBlock = async () => {
    if (!userToToggle?.id) return;
    await setDoc(doc(db, 'users', userToToggle.id), { isActive: !userToToggle.isActive }, { merge: true });
    setUserToToggle(null);
  };

  const confirmDeleteUser = async () => {
    if (!userToDelete?.id) return;
    await deleteDoc(doc(db, 'users', userToDelete.id));
    setUserToDelete(null);
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-slate-100 flex items-center gap-2 flex-wrap">
          <Shield className="w-6 h-6 text-blue-500" /> Painel de Administrador
        </h2>
        <p className="text-slate-400 text-sm">Gerencie quem tem acesso ao sistema (Área Restrita).</p>
      </div>

      <div className="bg-slate-900 rounded-xl border border-slate-800 p-4 sm:p-6">
        <h3 className="font-bold text-slate-200 mb-4 flex items-center gap-2">
          <UserPlus className="w-4 h-4" /> Criar Novo Usuário
        </h3>
        {feedbackMsg && (
          <div className={cn("mb-4 p-3 rounded-lg text-sm flex items-center gap-2", feedbackMsg.type === 'error' ? "bg-red-500/10 text-red-400" : "bg-green-500/10 text-green-400")}>
            {feedbackMsg.type === 'error' ? <AlertCircle className="w-4 h-4 shrink-0" /> : <CheckCircle2 className="w-4 h-4 shrink-0" />}
            <span>{feedbackMsg.text}</span>
          </div>
        )}
        <form onSubmit={handleCreateUser} className="grid grid-cols-1 md:grid-cols-4 gap-4 items-end">
          <div>
            <label className="block text-xs font-medium text-slate-400 mb-1">Nome de Usuário</label>
            <input type="text" name="username" required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg" />
          </div>
          <div>
            <label className="block text-xs font-medium text-slate-400 mb-1">Senha (Mín. 6)</label>
            <input type="text" name="password" minLength={6} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg" />
          </div>
          <div>
            <label className="block text-xs font-medium text-slate-400 mb-1">Permissão</label>
            <select name="role" required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg">
              <option value="Colaborador">Colaborador (Visualiza/Edita)</option>
              <option value="Administrador">Administrador (Total)</option>
            </select>
          </div>
          <button type="submit" disabled={isSaving} className="py-2.5 bg-blue-600 text-white font-bold rounded-lg hover:bg-blue-500 transition-colors disabled:opacity-50 md:col-span-1">
            {isSaving ? 'Criando...' : 'Adicionar Usuário'}
          </button>
        </form>
      </div>

      <div className="bg-slate-900 rounded-xl border border-slate-800 overflow-x-auto">
        <table className="w-full text-sm text-left">
          <thead className="bg-slate-800 text-slate-400 uppercase text-xs font-bold">
            <tr>
              <th className="px-4 py-3">Usuário</th>
              <th className="px-4 py-3">Permissão</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">Último Login</th>
              <th className="px-4 py-3 text-right">Ações</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800">
            {users.map(u => (
              <tr key={u.id} className={!u.isActive ? "opacity-50 bg-slate-900/50" : ""}>
                <td className="px-4 py-3 font-medium text-slate-200 whitespace-nowrap">{u.username}</td>
                <td className="px-4 py-3 whitespace-nowrap"><span className={cn("px-2 py-1 rounded text-xs font-bold", u.role === 'Administrador' ? "bg-amber-500/20 text-amber-400" : "bg-blue-500/20 text-blue-400")}>{u.role}</span></td>
                <td className="px-4 py-3 text-xs font-bold uppercase whitespace-nowrap">{u.isActive ? <span className="text-green-400">Ativo</span> : <span className="text-red-400">Bloqueado</span>}</td>
                <td className="px-4 py-3 text-slate-400 text-xs whitespace-nowrap">{u.lastLogin ? fmtDataHoraBR(u.lastLogin) : 'Nunca acessou'}</td>
                <td className="px-4 py-3 flex items-center justify-end gap-2 min-w-[200px]">
                  <button onClick={() => setEditingUser(u)} className="px-3 py-1 bg-blue-500/10 hover:bg-blue-500/20 text-blue-400 rounded text-xs font-bold transition-colors">Editar</button>
                  <button onClick={() => setUserToToggle(u)} className="px-3 py-1 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded text-xs font-bold transition-colors">
                    {u.isActive ? 'Bloquear' : 'Desbloquear'}
                  </button>
                  <button onClick={() => setUserToDelete(u)} className="px-3 py-1 bg-red-500/10 hover:bg-red-500/20 text-red-500 rounded text-xs font-bold transition-colors">Excluir</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Modal de Edição de Usuário */}
      {editingUser && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-slate-900 rounded-2xl shadow-2xl w-full max-w-sm p-6 border border-slate-700">
            <div className="flex items-center gap-3 mb-4 text-blue-400">
              <Shield className="w-6 h-6" />
              <h3 className="text-lg font-bold">Editar Usuário</h3>
            </div>
            <form onSubmit={async (e) => {
              e.preventDefault();
              setIsSaving(true);
              const formData = new FormData(e.currentTarget);
              try {
                await setDoc(doc(db, 'users', editingUser.id!), {
                  password: formData.get('password'),
                  role: formData.get('role')
                }, { merge: true });
                setEditingUser(null);
                setFeedbackMsg({ type: 'success', text: 'Usuário atualizado com sucesso!' });
                setTimeout(() => setFeedbackMsg(null), 3000);
              } catch (error) {
                console.error(error);
                setFeedbackMsg({ type: 'error', text: 'Erro ao atualizar usuário.' });
              } finally {
                setIsSaving(false);
              }
            }}>
              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-medium text-slate-400 mb-1">Usuário</label>
                  <input type="text" value={editingUser.username} disabled className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-slate-500 rounded-lg cursor-not-allowed" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-400 mb-1">Nova Senha</label>
                  <input type="text" name="password" defaultValue={editingUser.password} minLength={6} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg outline-none focus:border-blue-500" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-400 mb-1">Permissão</label>
                  <select name="role" defaultValue={editingUser.role} required className="w-full px-3 py-2 bg-slate-800 border border-slate-700 text-white rounded-lg outline-none focus:border-blue-500">
                    <option value="Colaborador">Colaborador (Visualiza/Edita)</option>
                    <option value="Administrador">Administrador (Total)</option>
                  </select>
                </div>
              </div>
              <div className="flex gap-2 mt-6">
                <button type="button" onClick={() => setEditingUser(null)} className="flex-1 py-2 bg-slate-800 text-slate-300 font-bold rounded-lg hover:bg-slate-700 transition-colors">Cancelar</button>
                <button type="submit" disabled={isSaving} className="flex-1 py-2 bg-blue-600 text-white font-bold rounded-lg hover:bg-blue-500 transition-colors disabled:opacity-50">
                  {isSaving ? 'Salvando...' : 'Salvar'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal de Bloqueio/Desbloqueio */}
      {userToToggle && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-slate-900 rounded-2xl shadow-2xl w-full max-w-sm p-6 border border-slate-700">
            <div className="flex items-center gap-3 mb-4 text-amber-500">
              <AlertCircle className="w-6 h-6" />
              <h3 className="text-lg font-bold">{userToToggle.isActive ? 'Bloquear' : 'Desbloquear'} Usuário</h3>
            </div>
            <p className="text-sm text-slate-400 mb-6">
              Deseja realmente {userToToggle.isActive ? 'bloquear' : 'desbloquear'} o acesso de <strong className="text-slate-200">{userToToggle.username}</strong> ao sistema?
            </p>
            <div className="flex gap-3">
              <button onClick={() => setUserToToggle(null)} className="flex-1 py-2.5 bg-slate-800 text-slate-300 font-bold rounded-lg hover:bg-slate-700 transition-colors">
                Cancelar
              </button>
              <button onClick={confirmToggleBlock} className={cn("flex-1 py-2.5 text-white font-bold rounded-lg transition-colors", userToToggle.isActive ? "bg-amber-600 hover:bg-amber-500" : "bg-blue-600 hover:bg-blue-500")}>
                Sim, {userToToggle.isActive ? 'Bloquear' : 'Desbloquear'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal de Exclusão de Usuário */}
      {userToDelete && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-slate-900 rounded-2xl shadow-2xl w-full max-w-sm p-6 border border-slate-700">
            <div className="flex items-center gap-3 mb-4 text-red-500">
              <Trash2 className="w-6 h-6" />
              <h3 className="text-lg font-bold">Excluir Usuário</h3>
            </div>
            <p className="text-sm text-slate-400 mb-6">
              Tem certeza que deseja apagar o usuário <strong className="text-slate-200">{userToDelete.username}</strong> permanentemente? Esta ação não pode ser desfeita.
            </p>
            <div className="flex gap-3">
              <button onClick={() => setUserToDelete(null)} className="flex-1 py-2.5 bg-slate-800 text-slate-300 font-bold rounded-lg hover:bg-slate-700 transition-colors">
                Cancelar
              </button>
              <button onClick={confirmDeleteUser} className="flex-1 py-2.5 bg-red-600 text-white font-bold rounded-lg hover:bg-red-500 transition-colors">
                Sim, Excluir
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function ReportCard({ active, onClick, label, icon }: { active: boolean, onClick: () => void, label: string, icon: React.ReactNode }) {
  return (
    <button 
      onClick={onClick}
      className={cn(
        "p-4 rounded-xl border flex flex-col items-center gap-2 transition-all text-center",
        active 
          ? "bg-blue-600 text-white border-blue-700 shadow-lg shadow-blue-500/40 transform scale-105" 
          : "bg-slate-800 text-slate-300 border-slate-700 hover:border-blue-500"
      )}
    >
      {icon}
      <span className="text-xs font-bold">{label}</span>
    </button>
  );
}
