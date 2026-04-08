"""Exporta .jsonl de agent-transcripts do Cursor para Markdown legível."""
import json
import re
import sys
from pathlib import Path


def extract_blocks(content):
    if not content:
        return []
    if isinstance(content, str):
        return [("text", content)]
    out = []
    for block in content:
        if not isinstance(block, dict):
            continue
        t = block.get("type")
        if t == "text":
            out.append(("text", block.get("text", "")))
        elif t == "tool_use":
            name = block.get("name", "?")
            inp = block.get("input") or {}
            desc = inp.get("description") or inp.get("command") or ""
            if desc and len(str(desc)) > 120:
                desc = str(desc)[:117] + "..."
            out.append(("tool", f"{name}" + (f" — {desc}" if desc else "")))
    return out


def clean_user_text(text: str) -> str:
    m = re.search(r"<user_query>\s*(.*?)\s*</user_query>", text, re.DOTALL | re.IGNORECASE)
    if m:
        return m.group(1).strip()
    return text.strip()


def jsonl_to_md(jsonl_path: Path, md_path: Path, title: str) -> None:
    parts = [
        f"# {title}\n\n",
        "Este arquivo foi gerado a partir do histórico salvo pelo Cursor (`agent-transcripts`). ",
        "Referências a imagens aparecem como texto; os arquivos de imagem podem estar na pasta de assets do projeto no Cursor.\n\n",
        "---\n\n",
    ]
    with jsonl_path.open(encoding="utf-8") as f:
        for raw in f:
            raw = raw.strip()
            if not raw:
                continue
            try:
                obj = json.loads(raw)
            except json.JSONDecodeError:
                continue
            role = obj.get("role")
            msg = obj.get("message") or {}
            blocks = extract_blocks(msg.get("content"))
            if role == "user":
                texts = [b[1] for b in blocks if b[0] == "text"]
                merged = "\n\n".join(texts)
                merged = clean_user_text(merged)
                if "[Image]" in merged or "<image_files>" in merged:
                    parts.append("### Você\n\n*(mensagem com imagem anexada — texto livre pode estar vazio)*\n\n")
                    if merged and len(merged) < 800:
                        parts.append(merged + "\n\n")
                elif merged:
                    parts.append("### Você\n\n" + merged + "\n\n")
                else:
                    parts.append("### Você\n\n*(sem texto)*\n\n")
            elif role == "assistant":
                chunk = []
                for kind, val in blocks:
                    val = val.replace("[REDACTED]", "").strip()
                    if not val:
                        continue
                    if kind == "text":
                        chunk.append(val)
                    else:
                        chunk.append(f"\n\n*({val})*\n\n")
                body = "\n".join(chunk).strip()
                if body:
                    parts.append("### Assistente\n\n" + body + "\n\n---\n\n")
    md_path.parent.mkdir(parents=True, exist_ok=True)
    md_path.write_text("".join(parts), encoding="utf-8")


def main():
    base = Path.home() / ".cursor/projects/c-Users-AMTK-Est-gio-Desktop-ProjetosPessoais-Freela-Sistema-da-escola/agent-transcripts"
    out_dir = Path(__file__).resolve().parent
    exports = [
        (
            base / "1976a9e6-3279-4ef0-a9a6-cd30adab2254/1976a9e6-3279-4ef0-a9a6-cd30adab2254.jsonl",
            out_dir / "CONVERSA-01-Flutter-Firebase-ambiente.md",
            "Conversa 1 — Ambiente Flutter + Firebase",
        ),
        (
            base / "5e4e773b-a264-48a2-8984-6a844c0aac15/5e4e773b-a264-48a2-8984-6a844c0aac15.jsonl",
            out_dir / "CONVERSA-02-Sistema-escolar-especificacao-e-etapas.md",
            "Conversa 2 — Sistema escolar (escopo, PASSOS e Firebase)",
        ),
    ]
    for src, dst, title in exports:
        if not src.is_file():
            print(f"Arquivo não encontrado: {src}", file=sys.stderr)
            sys.exit(1)
        jsonl_to_md(src, dst, title)
        print(f"OK: {dst}")
    print("Exportação concluída.")


if __name__ == "__main__":
    main()
