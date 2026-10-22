"""把 content/units.txt 的扩展单元合并进 careers.json，并检查内容。

用法：python scripts/build-units.py
顶层 words/grammar/dialogue 保持为第 1 单元（网页版与旧进度继续可用），扩展单元写入 units。
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "content" / "units.txt"
TARGETS = [ROOT / "public" / "careers.json", ROOT / "ios" / "LingoGarden" / "careers.json"]


def fields(line, count, where):
    parts = [p.strip() for p in line.split("|")]
    if len(parts) != count or not all(parts):
        sys.exit(f"{where}: 需要 {count} 个非空字段，实际 {len(parts)} 个：{line}")
    return parts


def parse(text):
    careers, career, unit = [], None, None
    for number, raw in enumerate(text.splitlines(), 1):
        line = raw.strip()
        where = f"units.txt 第 {number} 行"
        if not line:
            continue
        if line.startswith("# career:"):
            parts = [p.strip() for p in line[len("# career:"):].split("|")]
            career = {"id": parts[0], "meta": parts[1:], "units": []}
            careers.append(career)
        elif line.startswith("## unit:"):
            uid, title, level = fields(line[len("## unit:"):], 3, where)
            unit = {"id": uid, "title": title, "level": level, "words": [], "grammar": [], "dialogue": []}
            career["units"].append(unit)
        elif line.startswith("#"):
            continue
        elif line.startswith("w:"):
            term, meaning, example, translation = fields(line[2:], 4, where)
            unit["words"].append({"id": f"{unit['id']}-w{len(unit['words'])}", "term": term, "meaning": meaning, "example": example, "translation": translation})
        elif line.startswith("g:"):
            title, pattern, explanation, example, translation, prompt, options, answer = fields(line[2:], 8, where)
            unit["grammar"].append({"id": f"{unit['id']}-g{len(unit['grammar'])}", "title": title, "pattern": pattern, "explanation": explanation, "example": example, "translation": translation, "prompt": prompt, "options": [o.strip() for o in options.split(" / ")], "answer": answer})
        elif line.startswith("d:"):
            speaker, english, translation = fields(line[2:], 3, where)
            unit["dialogue"].append({"speaker": speaker, "english": english, "translation": translation})
        else:
            sys.exit(f"{where}: 无法识别：{line}")
    return careers


def all_units(career):
    base = {"id": career["id"], "words": career["words"], "grammar": career["grammar"], "dialogue": career["dialogue"]}
    return [base] + career.get("units", [])


def validate(careers):
    errors, ids = [], set()
    for career in careers:
        terms, meanings = {}, {}
        for unit in all_units(career):
            where = f"{career['id']} / {unit['id']}"
            if len(unit["words"]) < 6 or len(unit["grammar"]) < 2 or len(unit["dialogue"]) < 4:
                errors.append(f"{where}: 每单元至少 6 词、2 语法、4 句对话")
            for word in unit["words"]:
                for key, seen in (("term", terms), ("meaning", meanings)):
                    value = word[key].lower()
                    if value in seen:
                        errors.append(f"{where}: {key}「{word[key]}」与 {seen[value]} 重复（同一身份内必须唯一，否则选择题会出现两个相同选项）")
                    seen[value] = word["id"]
                if word["term"].lower() not in word["example"].lower():
                    errors.append(f"{where}: 例句没有包含单词「{word['term']}」，无法出填空题")
            for grammar in unit["grammar"]:
                if grammar["answer"] not in grammar["options"] or len(set(grammar["options"])) != len(grammar["options"]):
                    errors.append(f"{where}: 语法题 {grammar['id']} 的答案不在选项中或选项重复")
            for item in unit["words"] + unit["grammar"]:
                if item["id"] in ids:
                    errors.append(f"{where}: id 重复 {item['id']}")
                ids.add(item["id"])
    return errors


def main():
    careers = json.loads(TARGETS[0].read_text(encoding="utf-8"))
    by_id = {c["id"]: c for c in careers}
    for source in parse(SOURCE.read_text(encoding="utf-8")):
        units = source["units"]
        if source["id"] in by_id:
            by_id[source["id"]]["units"] = units
            continue
        if len(source["meta"]) != 5 or not units or units[0]["id"] != source["id"]:
            sys.exit(f"新身份 {source['id']} 需要 名称|英文|副标题|图标|SF Symbol，且第一个单元 id 与身份 id 相同")
        name, english, subtitle, icon, symbol = source["meta"]
        base = units[0]
        career = {"id": source["id"], "name": name, "english": english, "subtitle": subtitle, "icon": icon, "symbol": symbol,
                  "words": base["words"], "grammar": base["grammar"], "dialogue": base["dialogue"], "units": units[1:]}
        careers.append(career)
        by_id[career["id"]] = career
    errors = validate(careers)
    if errors:
        sys.exit("内容检查未通过：\n" + "\n".join(errors))
    text = json.dumps(careers, ensure_ascii=False, indent=2) + "\n"
    for target in TARGETS:
        target.write_text(text, encoding="utf-8", newline="\n")
    words = sum(len(u["words"]) for c in careers for u in all_units(c))
    grammar = sum(len(u["grammar"]) for c in careers for u in all_units(c))
    units = sum(len(all_units(c)) for c in careers)
    print(f"已生成：{len(careers)} 个身份，{units} 个单元，{words} 个单词，{grammar} 个语法点。")


if __name__ == "__main__":
    main()
