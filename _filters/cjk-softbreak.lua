-- 刪除兩個東亞全形字元之間的軟換行，避免中文段落在斷行處多出空格。
-- 效果等同 Pandoc 的 east_asian_line_breaks 擴充；Quarto 不會套用
-- _quarto.yml 裡 from: markdown+east_asian_line_breaks 的設定，所以改用篩選器。
-- 只處理前後都是純文字（Str）的軟換行，粗體、程式碼等元素旁的換行保留原樣。

local function is_east_asian(cp)
  return (cp >= 0x3000 and cp <= 0x303F)   -- 中日韓標點
      or (cp >= 0x3400 and cp <= 0x4DBF)   -- 擴充 A
      or (cp >= 0x4E00 and cp <= 0x9FFF)   -- 基本漢字
      or (cp >= 0xF900 and cp <= 0xFAFF)   -- 相容漢字
      or (cp >= 0xFF00 and cp <= 0xFFEF)   -- 全形字元與標點
end

local function last_codepoint(s)
  local last
  for _, cp in utf8.codes(s) do last = cp end
  return last
end

local function first_codepoint(s)
  for _, cp in utf8.codes(s) do return cp end
end

function Inlines(inlines)
  local i = 2
  while i < #inlines do
    local prev, cur, nxt = inlines[i - 1], inlines[i], inlines[i + 1]
    if cur.t == "SoftBreak" and prev.t == "Str" and nxt.t == "Str" then
      local a, b = last_codepoint(prev.text), first_codepoint(nxt.text)
      if a and b and is_east_asian(a) and is_east_asian(b) then
        inlines:remove(i)
      else
        i = i + 1
      end
    else
      i = i + 1
    end
  end
  return inlines
end
