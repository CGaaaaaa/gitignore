// GitIgnore库 - 符合Git规范的简化实现

/// 表示一个gitignore文件解析后的规则集合
pub struct Gitignore {
  rules : Array[Rule]
}

/// 表示单个gitignore规则
struct Rule {
  pattern : String
  negated : Bool
  directory_only : Bool
  absolute : Bool
}

/// 路径检查结果
pub enum PathStatus {
  Ignored
  NotIgnored
} derive(Eq, Show)

/// 创建新的Gitignore实例
pub fn Gitignore::new() -> Gitignore {
  { rules: Array::new() }
}

/// 从字符串创建Gitignore实例
pub fn Gitignore::from_string(content : String) -> Gitignore {
  let gitignore = Gitignore::new()
  let lines = split_lines(content)
  
  for line in lines {
    let trimmed = trim_string(line)
    
    // 跳过空行和注释行
    if trimmed.is_empty() || starts_with_hash(trimmed) {
      continue
    }
    
    // 解析并添加规则
    gitignore.add_pattern(trimmed)
  }
  
  gitignore
}

/// 添加单个模式
pub fn add_pattern(self : Gitignore, pattern : String) -> Unit {
  let trimmed = trim_string(pattern)
  
  // 跳过空模式和注释
  if trimmed.is_empty() || starts_with_hash(trimmed) {
    return
  }
  
  match parse_rule(trimmed) {
    Some(rule) => self.rules.push(rule)
    None => ()
  }
}

/// 解析单个规则
fn parse_rule(pattern : String) -> Option[Rule] {
  if pattern.is_empty() {
    return None
  }
  
  let mut working_pattern = pattern
  let mut negated = false
  let mut directory_only = false
  let mut absolute = false
  
  // 检查否定模式（在处理转义字符之前）
  if starts_with_exclamation(working_pattern) && !starts_with_escaped_exclamation(working_pattern) {
    negated = true
    working_pattern = substring_from(working_pattern, 1)
  }
  
  // 处理转义字符
  working_pattern = unescape_pattern(working_pattern)
  
  // 检查目录专用模式
  if ends_with_slash(working_pattern) {
    directory_only = true
    working_pattern = substring_to(working_pattern, working_pattern.length() - 1)
  }
  
  // 检查绝对路径模式
  if starts_with_slash(working_pattern) {
    absolute = true
    working_pattern = substring_from(working_pattern, 1)
  } else if contains_slash(working_pattern) {
    absolute = true
  }
  
  Some({
    pattern: working_pattern,
    negated,
    directory_only,
    absolute
  })
}

/// 处理转义字符
fn unescape_pattern(pattern : String) -> String {
  let mut result = ""
  let mut i = 0
  let chars = pattern.to_array()
  
  while i < chars.length() {
    if chars[i] == '\\' && i + 1 < chars.length() {
      // 转义字符
      i = i + 1
      result = result + chars[i].to_string()
    } else {
      result = result + chars[i].to_string()
    }
    i = i + 1
  }
  
  result
}

/// 检查路径是否被忽略
pub fn is_ignored(self : Gitignore, path : String) -> Bool {
  self.check_path(path) == Ignored
}

/// 检查路径状态
pub fn check_path(self : Gitignore, path : String) -> PathStatus {
  let normalized_path = normalize_path(path)
  let mut result = NotIgnored
  
  // 按顺序应用规则，后面的规则会覆盖前面的
  for rule in self.rules {
    if matches_rule(rule, normalized_path) {
      result = if rule.negated { NotIgnored } else { Ignored }
    }
  }
  
  result
}

/// 标准化路径
fn normalize_path(path : String) -> String {
  let mut normalized = path
  
  // 移除开头的 ./
  if starts_with_dot_slash(normalized) {
    normalized = substring_from(normalized, 2)
  }
  
  // 移除开头的 /
  if starts_with_slash(normalized) {
    normalized = substring_from(normalized, 1)
  }
  
  normalized
}

/// 检查规则是否匹配路径
fn matches_rule(rule : Rule, path : String) -> Bool {
  // 目录专用规则只匹配目录路径
  if rule.directory_only && !is_directory_path(path) {
    return false
  }
  
  // 应用匹配逻辑
  if rule.absolute {
    matches_absolute_pattern(rule.pattern, path)
  } else {
    matches_relative_pattern(rule.pattern, path)
  }
}

/// 检查是否为目录路径
fn is_directory_path(path : String) -> Bool {
  // 简化实现：对于目录专用模式，我们假设所有路径都可能是目录
  // 在实际应用中，这需要文件系统信息
  // 这里我们采用宽松的策略：目录专用模式匹配所有路径
  true
}

/// 绝对路径匹配
fn matches_absolute_pattern(pattern : String, path : String) -> Bool {
  // 处理双星号模式
  if contains_double_star(pattern) {
    matches_double_star_pattern(pattern, path, true)
  } else if has_wildcards(pattern) {
    matches_glob_pattern(pattern, path)
  } else {
    // 字面匹配
    path == pattern || starts_with_pattern_slash(path, pattern)
  }
}

/// 相对路径匹配
fn matches_relative_pattern(pattern : String, path : String) -> Bool {
  // 处理双星号模式
  if contains_double_star(pattern) {
    return matches_double_star_pattern(pattern, path, false)
  } else if has_wildcards(pattern) {
    // 通配符匹配 - 可以匹配路径的任何部分
    if matches_glob_pattern(pattern, path) {
      return true
    }
    
    // 尝试匹配路径的各个部分
    let parts = split_path(path)
    
    for i in 0..<parts.length() {
      let sub_path = join_array_slice(parts, i, parts.length(), "/")
      if matches_glob_pattern(pattern, sub_path) {
        return true
      }
    }
    
    // 尝试匹配单个部分
    for part in parts {
      if matches_glob_pattern(pattern, part) {
        return true
      }
    }
    
    false
  } else {
    // 字面匹配 - 相对模式可以匹配路径的任何部分
    if path == pattern {
      return true
    }
    
    // 检查是否作为路径的一部分出现
    let parts = split_path(path)
    for part in parts {
      if part == pattern {
        return true
      }
    }
    
    // 检查是否作为子路径出现
    for i in 0..<parts.length() {
      let sub_path = join_array_slice(parts, i, parts.length(), "/")
      if sub_path == pattern {
        return true
      }
    }
    
    false
  }
}

/// 检查是否包含通配符
fn has_wildcards(pattern : String) -> Bool {
  contains_star(pattern) || contains_question(pattern) || contains_bracket(pattern)
}

/// 双星号模式匹配
fn matches_double_star_pattern(pattern : String, path : String, absolute : Bool) -> Bool {
  // 特殊处理 **/foo/** 这种既有前缀又有后缀双星号的模式
  if starts_with_double_star_slash(pattern) && ends_with_slash_double_star(pattern) {
    // **/foo/** 模式：提取中间部分
    let middle = substring_range(pattern, 3, pattern.length() - 3)
    if middle.is_empty() {
      // **/** 模式，匹配任何内容
      return true
    }
    
    // 检查路径是否包含这个中间部分
    if path == middle {
      return true
    }
    
    // 检查路径是否以 middle/ 开头
    if starts_with_pattern_slash(path, middle) {
      return true
    }
    
    // 检查路径是否包含 /middle/ 或以 /middle 结尾
    let parts = split_path(path)
    for i in 0..<parts.length() {
      let sub_path = join_array_slice(parts, i, parts.length(), "/")
      if sub_path == middle || starts_with_pattern_slash(sub_path, middle) {
        return true
      }
    }
    
    return false
  } else if starts_with_double_star_slash(pattern) {
    // **/foo 模式
    let suffix = substring_from(pattern, 3)
    matches_leading_double_star(suffix, path, absolute)
  } else if ends_with_slash_double_star(pattern) {
    // foo/** 模式
    let prefix = substring_to(pattern, pattern.length() - 3)
    matches_trailing_double_star(prefix, path, absolute)
  } else if contains_slash_double_star_slash(pattern) {
    // foo/**/bar 模式
    matches_middle_double_star(pattern, path, absolute)
  } else {
    // 其他情况，当作普通模式处理
    let simple_pattern = replace_double_star_with_star(pattern)
    if absolute {
      matches_glob_pattern(simple_pattern, path)
    } else {
      matches_relative_pattern(simple_pattern, path)
    }
  }
}

/// 匹配开头双星号
fn matches_leading_double_star(suffix : String, path : String, absolute : Bool) -> Bool {
  if suffix.is_empty() {
    return true
  }
  
  // 检查直接匹配
  if path == suffix {
    return true
  }
  
  // 检查以 /suffix 结尾
  if ends_with_slash_pattern(path, suffix) {
    return true
  }
  
  // 对于 **/pattern 形式，pattern 可以匹配路径的任何部分
  // 例如 **/*.class 应该匹配 Main.class
  if has_wildcards(suffix) {
    // 如果 suffix 本身包含通配符，尝试匹配
    if matches_glob_pattern(suffix, path) {
      return true
    }
    
    // 尝试匹配路径的各个部分
    let parts = split_path(path)
    for i in 0..<parts.length() {
      let sub_path = join_array_slice(parts, i, parts.length(), "/")
      if matches_glob_pattern(suffix, sub_path) {
        return true
      }
    }
  }
  
  false
}

/// 匹配结尾双星号
fn matches_trailing_double_star(prefix : String, path : String, absolute : Bool) -> Bool {
  if absolute {
    // 绝对路径：必须从开头匹配
    path == prefix || starts_with_pattern_slash(path, prefix)
  } else {
    // 相对路径：可以匹配路径的任何部分
    if path == prefix {
      return true
    }
    
    // 检查路径是否以 prefix/ 开头
    if starts_with_pattern_slash(path, prefix) {
      return true
    }
    
    // 检查路径是否包含 /prefix/ 或以 /prefix 结尾
    let parts = split_path(path)
    for i in 0..<parts.length() {
      let sub_path = join_array_slice(parts, i, parts.length(), "/")
      if sub_path == prefix || starts_with_pattern_slash(sub_path, prefix) {
        return true
      }
    }
    
    false
  }
}

/// 匹配中间双星号
fn matches_middle_double_star(pattern : String, path : String, absolute : Bool) -> Bool {
  // 简化实现：找到/**/的位置并分割
  let parts = split_on_slash_double_star_slash(pattern)
  if parts.length() != 2 {
    return false
  }
  
  let prefix = parts[0]
  let suffix = parts[1]
  
  if absolute {
    // 绝对路径：必须从开头匹配 prefix
    if path == prefix {
      return suffix.is_empty()
    } else if starts_with_pattern_slash(path, prefix) {
      let remaining = substring_from(path, prefix.length() + 1)
      return remaining == suffix || ends_with_slash_pattern(remaining, suffix)
    } else {
      return false
    }
  } else {
    // 相对路径：可以匹配路径的任何部分
    let path_parts = split_path(path)
    
    // 寻找 prefix 的位置
    for i in 0..<path_parts.length() {
      if path_parts[i] == prefix {
        // 从 prefix 后面开始寻找 suffix
        for j in (i + 1)..=path_parts.length() {
          let remaining = join_array_slice(path_parts, j, path_parts.length(), "/")
          if remaining == suffix || ends_with_slash_pattern(remaining, suffix) {
            return true
          }
        }
      }
    }
    
    false
  }
}

/// 通配符模式匹配（简化实现）
fn matches_glob_pattern(pattern : String, text : String) -> Bool {
  // 简化的glob匹配实现
  if pattern == "*" {
    return true
  }
  
  if starts_with_star(pattern) && ends_with_star(pattern) {
    let middle = substring_range(pattern, 1, pattern.length() - 1)
    return text.contains(middle)
  }
  
  if starts_with_star(pattern) {
    let suffix = substring_from(pattern, 1)
    return ends_with_pattern(text, suffix)
  }
  
  if ends_with_star(pattern) {
    let prefix = substring_to(pattern, pattern.length() - 1)
    return starts_with_pattern(text, prefix)
  }
  
  if contains_star(pattern) {
    // 处理中间有*的情况
    let star_pos = find_star_position(pattern)
    if star_pos >= 0 {
      let prefix = substring_to(pattern, star_pos)
      let suffix = substring_from(pattern, star_pos + 1)
      return starts_with_pattern(text, prefix) && ends_with_pattern(text, suffix)
    }
  }
  
  // 处理 ? 通配符
  if contains_question(pattern) {
    return matches_question_pattern(pattern, text)
  }
  
  // 处理字符类 [a-z] - 需要特殊的匹配逻辑
  if contains_bracket(pattern) {
    return matches_bracket_pattern(pattern, text)
  }
  
  // 字面匹配
  pattern == text
}

/// 问号模式匹配
fn matches_question_pattern(pattern : String, text : String) -> Bool {
  if pattern.length() != text.length() {
    return false
  }
  
  let pattern_chars = pattern.to_array()
  let text_chars = text.to_array()
  
  for i in 0..<pattern_chars.length() {
    if pattern_chars[i] != '?' && pattern_chars[i] != text_chars[i] {
      return false
    }
  }
  
  true
}

/// 字符类模式匹配（完整实现）
fn matches_bracket_pattern(pattern : String, text : String) -> Bool {
  // 使用更通用的匹配算法来处理包含字符类的模式
  matches_pattern_with_brackets(pattern, text, 0, 0)
}

/// 递归匹配包含字符类的模式
fn matches_pattern_with_brackets(pattern : String, text : String, p_idx : Int, t_idx : Int) -> Bool {
  let pattern_chars = pattern.to_array()
  let text_chars = text.to_array()
  
  if p_idx >= pattern_chars.length() {
    return t_idx >= text_chars.length()
  }
  
  if t_idx >= text_chars.length() {
    // 检查剩余的模式是否都是可选的
    return p_idx >= pattern_chars.length()
  }
  
  if pattern_chars[p_idx] == '[' {
    // 查找闭合的 ]
    let mut bracket_end = p_idx + 1
    while bracket_end < pattern_chars.length() && pattern_chars[bracket_end] != ']' {
      bracket_end = bracket_end + 1
    }
    
    if bracket_end >= pattern_chars.length() {
      return false // 没有找到闭合的 ]
    }
    
    // 提取字符类内容
    let mut char_class = ""
    for k in (p_idx + 1)..<bracket_end {
      char_class = char_class + pattern_chars[k].to_string()
    }
    
    // 检查字符是否匹配字符类
    if matches_char_in_class(text_chars[t_idx], char_class) {
      return matches_pattern_with_brackets(pattern, text, bracket_end + 1, t_idx + 1)
    } else {
      return false
    }
  } else if pattern_chars[p_idx] == '?' {
    // 问号匹配任意字符（除了 /）
    if text_chars[t_idx] != '/' {
      return matches_pattern_with_brackets(pattern, text, p_idx + 1, t_idx + 1)
    } else {
      return false
    }
  } else if pattern_chars[p_idx] == '*' {
    // 星号匹配任意字符序列（除了 /）
    // 尝试匹配0个字符
    if matches_pattern_with_brackets(pattern, text, p_idx + 1, t_idx) {
      return true
    }
    
    // 尝试匹配更多字符
    let mut i = t_idx
    while i < text_chars.length() && text_chars[i] != '/' {
      i = i + 1
      if matches_pattern_with_brackets(pattern, text, p_idx + 1, i) {
        return true
      }
    }
    
    false
  } else {
    // 字面字符匹配
    if pattern_chars[p_idx] == text_chars[t_idx] {
      return matches_pattern_with_brackets(pattern, text, p_idx + 1, t_idx + 1)
    } else {
      return false
    }
  }
}

/// 检查字符是否匹配字符类
fn matches_char_in_class(c : Char, char_class : String) -> Bool {
  let chars = char_class.to_array()
  let mut i = 0
  
  while i < chars.length() {
    if i + 2 < chars.length() && chars[i + 1] == '-' {
      // 范围匹配，如 a-z
      let start_char = chars[i]
      let end_char = chars[i + 2]
      if c >= start_char && c <= end_char {
        return true
      }
      i = i + 3
    } else {
      // 单个字符匹配
      if c == chars[i] {
        return true
      }
      i = i + 1
    }
  }
  
  false
}

// 辅助函数：字符串操作

/// 分割行
fn split_lines(content : String) -> Array[String] {
  let lines = Array::new()
  let mut current_line = ""
  let chars = content.to_array()
  
  for char in chars {
    if char == '\n' {
      lines.push(current_line)
      current_line = ""
    } else if char != '\r' {
      current_line = current_line + char.to_string()
    }
  }
  
  if !current_line.is_empty() {
    lines.push(current_line)
  }
  
  lines
}

/// 分割路径
fn split_path(path : String) -> Array[String] {
  let parts = Array::new()
  let mut current_part = ""
  let chars = path.to_array()
  
  for char in chars {
    if char == '/' {
      if !current_part.is_empty() {
        parts.push(current_part)
        current_part = ""
      }
    } else {
      current_part = current_part + char.to_string()
    }
  }
  
  if !current_part.is_empty() {
    parts.push(current_part)
  }
  
  parts
}

/// 去除字符串首尾空白
fn trim_string(s : String) -> String {
  let chars = s.to_array()
  let mut start = 0
  let mut end = chars.length()
  
  // 找到第一个非空白字符
  while start < end && is_whitespace(chars[start]) {
    start = start + 1
  }
  
  // 找到最后一个非空白字符
  while end > start && is_whitespace(chars[end - 1]) {
    end = end - 1
  }
  
  if start == 0 && end == chars.length() {
    s
  } else {
    String::from_array(slice_array(chars, start, end))
  }
}

/// 检查是否为空白字符
fn is_whitespace(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\r' || c == '\n'
}

/// 连接数组片段
fn join_array_slice(arr : Array[String], start : Int, end : Int, separator : String) -> String {
  if start >= end || start >= arr.length() {
    return ""
  }
  
  let actual_end = if end > arr.length() { arr.length() } else { end }
  let mut result = arr[start]
  
  for i in (start + 1)..<actual_end {
    result = result + separator + arr[i]
  }
  
  result
}

/// 数组切片
fn slice_array[T](arr : Array[T], start : Int, end : Int) -> Array[T] {
  let result = Array::new()
  let actual_start = if start < 0 { 0 } else { start }
  let actual_end = if end > arr.length() { arr.length() } else { end }
  
  for i in actual_start..<actual_end {
    result.push(arr[i])
  }
  
  result
}

// 字符串检查函数

fn starts_with_hash(s : String) -> Bool {
  !s.is_empty() && s.to_array()[0] == '#'
}

fn starts_with_exclamation(s : String) -> Bool {
  !s.is_empty() && s.to_array()[0] == '!'
}

fn starts_with_escaped_exclamation(s : String) -> Bool {
  s.length() >= 2 && s.to_array()[0] == '\\' && s.to_array()[1] == '!'
}

fn starts_with_slash(s : String) -> Bool {
  !s.is_empty() && s.to_array()[0] == '/'
}

fn starts_with_dot_slash(s : String) -> Bool {
  s.length() >= 2 && s.to_array()[0] == '.' && s.to_array()[1] == '/'
}

fn starts_with_star(s : String) -> Bool {
  !s.is_empty() && s.to_array()[0] == '*'
}

fn starts_with_double_star_slash(s : String) -> Bool {
  s.length() >= 3 && s.to_array()[0] == '*' && s.to_array()[1] == '*' && s.to_array()[2] == '/'
}

fn starts_with_pattern(s : String, pattern : String) -> Bool {
  if pattern.length() > s.length() {
    return false
  }
  
  let s_chars = s.to_array()
  let p_chars = pattern.to_array()
  
  for i in 0..<p_chars.length() {
    if s_chars[i] != p_chars[i] {
      return false
    }
  }
  
  true
}

fn starts_with_pattern_slash(s : String, pattern : String) -> Bool {
  let pattern_slash = pattern + "/"
  starts_with_pattern(s, pattern_slash)
}

fn ends_with_slash(s : String) -> Bool {
  !s.is_empty() && s.to_array()[s.length() - 1] == '/'
}

fn ends_with_star(s : String) -> Bool {
  !s.is_empty() && s.to_array()[s.length() - 1] == '*'
}

fn ends_with_slash_double_star(s : String) -> Bool {
  s.length() >= 3 && 
  s.to_array()[s.length() - 3] == '/' &&
  s.to_array()[s.length() - 2] == '*' &&
  s.to_array()[s.length() - 1] == '*'
}

fn ends_with_pattern(s : String, pattern : String) -> Bool {
  if pattern.length() > s.length() {
    return false
  }
  
  let s_chars = s.to_array()
  let p_chars = pattern.to_array()
  let offset = s.length() - pattern.length()
  
  for i in 0..<p_chars.length() {
    if s_chars[offset + i] != p_chars[i] {
      return false
    }
  }
  
  true
}

fn ends_with_slash_pattern(s : String, pattern : String) -> Bool {
  let slash_pattern = "/" + pattern
  ends_with_pattern(s, slash_pattern)
}

fn contains_slash(s : String) -> Bool {
  let chars = s.to_array()
  for c in chars {
    if c == '/' {
      return true
    }
  }
  false
}

fn contains_dot(s : String) -> Bool {
  let chars = s.to_array()
  for c in chars {
    if c == '.' {
      return true
    }
  }
  false
}

fn contains_star(s : String) -> Bool {
  let chars = s.to_array()
  for c in chars {
    if c == '*' {
      return true
    }
  }
  false
}

fn contains_question(s : String) -> Bool {
  let chars = s.to_array()
  for c in chars {
    if c == '?' {
      return true
    }
  }
  false
}

fn contains_bracket(s : String) -> Bool {
  let chars = s.to_array()
  for c in chars {
    if c == '[' {
      return true
    }
  }
  false
}

fn contains_double_star(s : String) -> Bool {
  s.contains("**")
}

fn contains_slash_double_star_slash(s : String) -> Bool {
  s.contains("/**/")
}

fn contains_slash_pattern_slash(s : String, pattern : String) -> Bool {
  let slash_pattern_slash = "/" + pattern + "/"
  s.contains(slash_pattern_slash)
}

// 字符串操作函数

fn substring_from(s : String, start : Int) -> String {
  let chars = s.to_array()
  if start >= chars.length() {
    return ""
  }
  
  String::from_array(slice_array(chars, start, chars.length()))
}

fn substring_to(s : String, end : Int) -> String {
  let chars = s.to_array()
  if end <= 0 {
    return ""
  }
  
  let actual_end = if end > chars.length() { chars.length() } else { end }
  String::from_array(slice_array(chars, 0, actual_end))
}

fn substring_range(s : String, start : Int, end : Int) -> String {
  let chars = s.to_array()
  if start >= chars.length() || start >= end {
    return ""
  }
  
  let actual_end = if end > chars.length() { chars.length() } else { end }
  String::from_array(slice_array(chars, start, actual_end))
}

fn replace_double_star_with_star(s : String) -> String {
  s.replace(old="**", new="*")
}

fn split_on_slash_double_star_slash(s : String) -> Array[String] {
  // 简化实现：手动查找和分割
  let parts = Array::new()
  let pattern = "/**/"
  let pattern_len = 4
  let chars = s.to_array()
  let mut current = ""
  let mut i = 0
  
  while i <= chars.length() - pattern_len {
    if chars[i] == '/' && chars[i + 1] == '*' && chars[i + 2] == '*' && chars[i + 3] == '/' {
      // 找到了 /**/
      parts.push(current)
      current = ""
      i = i + pattern_len
    } else {
      current = current + chars[i].to_string()
      i = i + 1
    }
  }
  
  // 添加剩余字符
  while i < chars.length() {
    current = current + chars[i].to_string()
    i = i + 1
  }
  
  if !current.is_empty() || parts.length() > 0 {
    parts.push(current)
  }
  
  parts
}

fn find_star_position(s : String) -> Int {
  let chars = s.to_array()
  for i in 0..<chars.length() {
    if chars[i] == '*' {
      return i
    }
  }
  -1
} 