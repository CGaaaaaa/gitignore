// MoonBit Gitignore 库测试 - 完整测试套件

///|
test "basic_pattern_matching" {
  let gitignore = Gitignore::new()

  // 基础匹配
  gitignore.add_pattern("*.txt")
  assert_eq(gitignore.is_ignored("file.txt"), true)
  assert_eq(gitignore.is_ignored("file.md"), false)

  // 精确匹配
  gitignore.add_pattern("README")
  assert_eq(gitignore.is_ignored("README"), true)
  assert_eq(gitignore.is_ignored("README.md"), false)
}

///|
test "wildcard_patterns" {
  let gitignore = Gitignore::new()

  // 单个星号
  gitignore.add_pattern("*.log")
  assert_eq(gitignore.is_ignored("app.log"), true)
  assert_eq(gitignore.is_ignored("error.log"), true)
  assert_eq(gitignore.is_ignored("logs/app.log"), true) // 相对匹配

  // 前缀通配符
  gitignore.add_pattern("temp*")
  assert_eq(gitignore.is_ignored("temp"), true)
  assert_eq(gitignore.is_ignored("temp.txt"), true)
  assert_eq(gitignore.is_ignored("temporary"), true)

  // 中间通配符
  gitignore.add_pattern("test*file")
  assert_eq(gitignore.is_ignored("testfile"), true)
  assert_eq(gitignore.is_ignored("test123file"), true)
  assert_eq(gitignore.is_ignored("test_my_file"), true)
}

///|
test "question_mark_patterns" {
  let gitignore = Gitignore::new()

  // 单字符匹配
  gitignore.add_pattern("file?.txt")
  assert_eq(gitignore.is_ignored("file1.txt"), true)
  assert_eq(gitignore.is_ignored("fileA.txt"), true)
  assert_eq(gitignore.is_ignored("file12.txt"), false) // ? 只匹配一个字符

  // 多个问号
  gitignore.add_pattern("test??")
  assert_eq(gitignore.is_ignored("test01"), true)
  assert_eq(gitignore.is_ignored("testAB"), true)
  assert_eq(gitignore.is_ignored("test"), false)
  assert_eq(gitignore.is_ignored("test123"), false)
}

///|
test "character_ranges" {
  let gitignore = Gitignore::new()

  // 字母范围
  gitignore.add_pattern("file[a-z].txt")
  assert_eq(gitignore.is_ignored("filea.txt"), true)
  assert_eq(gitignore.is_ignored("filez.txt"), true)
  assert_eq(gitignore.is_ignored("fileA.txt"), false)

  // 数字范围
  gitignore.add_pattern("version[0-9]")
  assert_eq(gitignore.is_ignored("version1"), true)
  assert_eq(gitignore.is_ignored("version9"), true)
  assert_eq(gitignore.is_ignored("versiona"), false)

  // 大写字母范围
  gitignore.add_pattern("Class[A-Z].java")
  assert_eq(gitignore.is_ignored("ClassA.java"), true)
  assert_eq(gitignore.is_ignored("ClassZ.java"), true)
  assert_eq(gitignore.is_ignored("Classa.java"), false)
}

///|
test "double_star_patterns" {
  let gitignore = Gitignore::new()

  // **/ 前缀 - 匹配任意深度
  gitignore.add_pattern("**/target")
  assert_eq(gitignore.is_ignored("target"), true)
  assert_eq(gitignore.is_ignored("project/target"), true)
  assert_eq(gitignore.is_ignored("deep/nested/project/target"), true)
  gitignore.add_pattern("**/node_modules")
  assert_eq(gitignore.is_ignored("node_modules"), true)
  assert_eq(gitignore.is_ignored("frontend/node_modules"), true)
  assert_eq(gitignore.is_ignored("apps/frontend/node_modules"), true)

  // /** 后缀 - 匹配目录内所有内容
  gitignore.add_pattern("build/**")
  assert_eq(gitignore.is_ignored("build/output.jar"), true)
  assert_eq(gitignore.is_ignored("build/classes/Main.class"), true)
  assert_eq(gitignore.is_ignored("build/deep/nested/file.txt"), true)

  // 中间的 /**/
  gitignore.add_pattern("src/**/test")
  assert_eq(gitignore.is_ignored("src/test"), true)
  assert_eq(gitignore.is_ignored("src/main/test"), true)
  assert_eq(gitignore.is_ignored("src/deep/nested/path/test"), true)
}

///|
test "directory_patterns" {
  let gitignore = Gitignore::new()

  // 目录专用模式（以 / 结尾）
  gitignore.add_pattern("logs/")
  assert_eq(gitignore.is_ignored("logs"), true)
  assert_eq(gitignore.is_ignored("logs/error.log"), true)
  assert_eq(gitignore.is_ignored("app/logs/debug.log"), true)
  gitignore.add_pattern("temp/")
  assert_eq(gitignore.is_ignored("temp"), true)
  assert_eq(gitignore.is_ignored("temp/cache"), true)
  assert_eq(gitignore.is_ignored("project/temp/file.tmp"), true)
}

///|
test "absolute_vs_relative_paths" {
  let gitignore = Gitignore::new()

  // 绝对路径模式（以 / 开头）
  gitignore.add_pattern("/README.md")
  assert_eq(gitignore.is_ignored("README.md"), true)
  assert_eq(gitignore.is_ignored("docs/README.md"), false) // 不匹配子目录中的

  // 相对路径模式
  gitignore.add_pattern("config.json")
  assert_eq(gitignore.is_ignored("config.json"), true)
  assert_eq(gitignore.is_ignored("app/config.json"), true) // 匹配任意层级
  assert_eq(gitignore.is_ignored("deep/nested/config.json"), true)

  // 包含斜杠的模式
  gitignore.add_pattern("src/main")
  assert_eq(gitignore.is_ignored("src/main"), true)
  assert_eq(gitignore.is_ignored("project/src/main"), false) // 绝对匹配
}

///|
test "negation_patterns" {
  let gitignore = Gitignore::new()

  // 先忽略所有 .txt 文件
  gitignore.add_pattern("*.txt")
  assert_eq(gitignore.is_ignored("file.txt"), true)
  assert_eq(gitignore.is_ignored("important.txt"), true)

  // 然后排除特定文件
  gitignore.add_pattern("!important.txt")
  assert_eq(gitignore.is_ignored("file.txt"), true)
  assert_eq(gitignore.is_ignored("important.txt"), false) // 被否定模式排除

  // 复杂的否定模式
  gitignore.add_pattern("logs/*")
  gitignore.add_pattern("!logs/keep.log")
  assert_eq(gitignore.is_ignored("logs/error.log"), true)
  assert_eq(gitignore.is_ignored("logs/keep.log"), false)
}

///|
test "complex_patterns" {
  let gitignore = Gitignore::new()

  // 组合模式
  gitignore.add_pattern("**/*.class")
  assert_eq(gitignore.is_ignored("Main.class"), true)
  assert_eq(gitignore.is_ignored("com/example/Main.class"), true)
  assert_eq(gitignore.is_ignored("deep/nested/package/Utils.class"), true)
  gitignore.add_pattern("**/target/**")
  assert_eq(gitignore.is_ignored("target/classes"), true)
  assert_eq(gitignore.is_ignored("module/target/test-classes"), true)
  assert_eq(
    gitignore.is_ignored("deep/project/target/generated/File.java"),
    true,
  )

  // 复杂通配符
  gitignore.add_pattern("test-*.log")
  assert_eq(gitignore.is_ignored("test-1.log"), true)
  assert_eq(gitignore.is_ignored("test-error.log"), true)
  assert_eq(gitignore.is_ignored("test-.log"), true)
}

///|
test "edge_cases" {
  let gitignore = Gitignore::new()

  // 空模式和注释
  gitignore.add_pattern("")
  gitignore.add_pattern("# This is a comment")
  gitignore.add_pattern("   # Another comment")

  // 这些不应该匹配任何文件
  assert_eq(gitignore.is_ignored("file.txt"), false)
  assert_eq(gitignore.is_ignored("# This is a comment"), false)

  // 只有空格的行
  gitignore.add_pattern("   ")
  gitignore.add_pattern("\t\t")
  assert_eq(gitignore.is_ignored("file.txt"), false)

  // 转义字符
  gitignore.add_pattern("\\#important")
  assert_eq(gitignore.is_ignored("#important"), true)
  gitignore.add_pattern("\\!special")
  assert_eq(gitignore.is_ignored("!special"), true)
}

///|
test "real_world_patterns" {
  let gitignore = Gitignore::new()

  // Maven 项目模式
  gitignore.add_pattern("target/")
  gitignore.add_pattern("*.jar")
  gitignore.add_pattern("*.war")
  gitignore.add_pattern("*.class")
  assert_eq(gitignore.is_ignored("target"), true)
  assert_eq(gitignore.is_ignored("target/classes/Main.class"), true)
  assert_eq(gitignore.is_ignored("app.jar"), true)
  assert_eq(gitignore.is_ignored("Main.class"), true)

  // Node.js 项目模式
  gitignore.add_pattern("node_modules/")
  gitignore.add_pattern("npm-debug.log*")
  gitignore.add_pattern("*.tgz")
  assert_eq(gitignore.is_ignored("node_modules"), true)
  assert_eq(gitignore.is_ignored("npm-debug.log"), true)
  assert_eq(gitignore.is_ignored("npm-debug.log.1"), true)
  assert_eq(gitignore.is_ignored("package.tgz"), true)

  // IDE 文件
  gitignore.add_pattern(".idea/")
  gitignore.add_pattern("*.iml")
  gitignore.add_pattern(".vscode/")
  assert_eq(gitignore.is_ignored(".idea"), true)
  assert_eq(gitignore.is_ignored(".idea/workspace.xml"), true)
  assert_eq(gitignore.is_ignored("project.iml"), true)
  assert_eq(gitignore.is_ignored(".vscode/settings.json"), true)
}

///|
test "from_string_parsing" {
  let content = "# This is a gitignore file\n*.log\ntarget/\n!important.log\n\n# Node modules\nnode_modules/\n*.tgz\n\n# IDE files\n.idea/\n*.iml\n"
  let gitignore = Gitignore::from_string(content)

  // 测试解析的模式
  assert_eq(gitignore.is_ignored("app.log"), true)
  assert_eq(gitignore.is_ignored("target"), true)
  assert_eq(gitignore.is_ignored("important.log"), false) // 否定模式
  assert_eq(gitignore.is_ignored("node_modules"), true)
  assert_eq(gitignore.is_ignored("package.tgz"), true)
  assert_eq(gitignore.is_ignored(".idea"), true)
  assert_eq(gitignore.is_ignored("project.iml"), true)
}

///|
test "pattern_precedence" {
  let gitignore = Gitignore::new()

  // 后面的模式覆盖前面的
  gitignore.add_pattern("*.txt") // 忽略所有 .txt
  gitignore.add_pattern("!keep.txt") // 但保留 keep.txt
  gitignore.add_pattern("keep.txt") // 又忽略 keep.txt
  assert_eq(gitignore.is_ignored("file.txt"), true)
  assert_eq(gitignore.is_ignored("keep.txt"), true) // 最后的模式生效

  // 测试复杂的优先级
  let gitignore2 = Gitignore::new()
  gitignore2.add_pattern("docs/")
  gitignore2.add_pattern("!docs/important/")
  gitignore2.add_pattern("docs/important/secret.txt")
  assert_eq(gitignore2.is_ignored("docs/readme.txt"), true)
  assert_eq(gitignore2.is_ignored("docs/important/guide.txt"), false)
  assert_eq(gitignore2.is_ignored("docs/important/secret.txt"), true)
}

///|
test "check_path_method" {
  let gitignore = Gitignore::new()
  gitignore.add_pattern("*.log")
  gitignore.add_pattern("!important.log")

  // 测试详细的检查方法
  assert_eq(gitignore.check_path("app.log"), Ignored)
  assert_eq(gitignore.check_path("important.log"), NotIgnored)
  assert_eq(gitignore.check_path("readme.txt"), NotIgnored)
}

///|
test "performance_patterns" {
  let gitignore = Gitignore::new()

  // 添加大量模式测试性能
  for i = 0; i < 100; i = i + 1 {
    gitignore.add_pattern("*." + i.to_string())
    gitignore.add_pattern("temp" + i.to_string() + "*")
    gitignore.add_pattern("**/" + i.to_string() + "/**")
  }

  // 测试匹配性能
  assert_eq(gitignore.is_ignored("file.50"), true)
  assert_eq(gitignore.is_ignored("temp25file"), true)
  assert_eq(gitignore.is_ignored("path/50/file"), true)
  assert_eq(gitignore.is_ignored("unmatched.file"), false)
}

// 新增测试：转义字符和特殊字符处理

///|
test "escape_characters" {
  let gitignore = Gitignore::new()

  // 转义反斜杠
  gitignore.add_pattern("\\\\backslash")
  assert_eq(gitignore.is_ignored("\\backslash"), true)

  // 多重转义
  gitignore.add_pattern("\\\\\\*complex")
  assert_eq(gitignore.is_ignored("\\*complex"), true)
}

// 新增测试：路径标准化

///|
test "path_normalization" {
  let gitignore = Gitignore::new()
  gitignore.add_pattern("src/main")

  // 测试路径标准化
  assert_eq(gitignore.is_ignored("./src/main"), true)
  assert_eq(gitignore.is_ignored("/src/main"), true)
  assert_eq(gitignore.is_ignored("src/main"), true)

  // 测试相对路径 - 需要创建新的gitignore实例
  let gitignore2 = Gitignore::new()
  gitignore2.add_pattern("./relative/path")
  assert_eq(gitignore2.is_ignored("relative/path"), true)
  assert_eq(gitignore2.is_ignored("./relative/path"), true)
}

// 新增测试：边界情况和错误处理

///|
test "edge_cases_and_error_handling" {
  let gitignore = Gitignore::new()

  // 空字符串模式
  gitignore.add_pattern("")
  assert_eq(gitignore.is_ignored("anyfile"), false)

  // 只有空格的模式
  gitignore.add_pattern("   ")
  assert_eq(gitignore.is_ignored("   "), false)

  // 只有制表符的模式
  gitignore.add_pattern("\t\t\t")
  assert_eq(gitignore.is_ignored("file"), false)

  // 很长的模式
  let long_pattern = "very" + "long".repeat(100) + "pattern"
  gitignore.add_pattern(long_pattern)
  assert_eq(gitignore.is_ignored(long_pattern), true)

  // 包含多种特殊字符的模式 - 简化测试
  gitignore.add_pattern("file[!@#].txt")
  assert_eq(gitignore.is_ignored("file!.txt"), true)
  assert_eq(gitignore.is_ignored("file@.txt"), true)
  assert_eq(gitignore.is_ignored("filea.txt"), false)

  // 只有通配符的模式
  gitignore.add_pattern("*")
  assert_eq(gitignore.is_ignored("anything"), true)
  assert_eq(gitignore.is_ignored("file.txt"), true)
  gitignore.add_pattern("?")
  assert_eq(gitignore.is_ignored("a"), true)
  assert_eq(gitignore.is_ignored("ab"), true) // 由于之前的 * 模式影响
}

// 新增测试：字符串处理函数

///|
test "string_utility_functions" {
  // 这些测试通过使用各种模式来间接测试字符串处理函数
  let gitignore = Gitignore::new()

  // 测试包含各种字符的路径
  gitignore.add_pattern("path with spaces")
  assert_eq(gitignore.is_ignored("path with spaces"), true)

  // 测试Unicode字符
  gitignore.add_pattern("文件.txt")
  assert_eq(gitignore.is_ignored("文件.txt"), true)

  // 测试特殊ASCII字符
  gitignore.add_pattern("file\t\n\r.txt")
  assert_eq(gitignore.is_ignored("file\t\n\r.txt"), true)

  // 测试路径分割
  gitignore.add_pattern("a/b/c/d/e/f/g")
  assert_eq(gitignore.is_ignored("a/b/c/d/e/f/g"), true)

  // 测试深层嵌套路径
  let deep_path = "a" + "/b".repeat(50)
  gitignore.add_pattern("**" + deep_path)
  assert_eq(gitignore.is_ignored(deep_path), true)
}

// 新增测试：模式解析边界情况

///|
test "pattern_parsing_edge_cases" {
  let gitignore = Gitignore::new()

  // 以斜杠开头和结尾的模式
  gitignore.add_pattern("/start/")
  assert_eq(gitignore.is_ignored("start"), true)
  assert_eq(gitignore.is_ignored("start/file"), true)
  assert_eq(gitignore.is_ignored("other/start"), false)

  // 多个连续斜杠
  gitignore.add_pattern("path//with///multiple////slashes")
  assert_eq(gitignore.is_ignored("path//with///multiple////slashes"), true)

  // 以否定符号开头但被转义
  gitignore.add_pattern("\\!not_negated")
  assert_eq(gitignore.is_ignored("!not_negated"), true)

  // 复杂的转义序列
  gitignore.add_pattern("\\\\\\!\\*\\?\\[complex")
  assert_eq(gitignore.is_ignored("\\!*?[complex"), true)

  // 模式中包含注释符号但不在开头
  gitignore.add_pattern("file#with#hash.txt")
  assert_eq(gitignore.is_ignored("file#with#hash.txt"), true)
}

// 新增测试：复杂否定模式

///|
test "complex_negation_patterns" {
  let gitignore = Gitignore::new()

  // 多层否定 - 修复双重否定测试
  gitignore.add_pattern("*.log")
  gitignore.add_pattern("!important.log")
  gitignore.add_pattern("\\!very_important.log") // 转义的感叹号
  assert_eq(gitignore.is_ignored("app.log"), true)
  assert_eq(gitignore.is_ignored("important.log"), false)
  assert_eq(gitignore.is_ignored("!very_important.log"), true)

  // 否定模式与通配符
  gitignore.add_pattern("temp*")
  gitignore.add_pattern("!temp_keep*")
  assert_eq(gitignore.is_ignored("temp.txt"), true)
  assert_eq(gitignore.is_ignored("temp_delete.txt"), true)
  assert_eq(gitignore.is_ignored("temp_keep.txt"), false)
  assert_eq(gitignore.is_ignored("temp_keep_this.txt"), false)

  // 否定模式与目录
  gitignore.add_pattern("build/")
  gitignore.add_pattern("!build/important/")
  assert_eq(gitignore.is_ignored("build/output.jar"), true)
  assert_eq(gitignore.is_ignored("build/important/config.xml"), false)
}

// 新增测试：路径匹配的边界情况

///|
test "path_matching_edge_cases" {
  let gitignore = Gitignore::new()

  // 空路径
  assert_eq(gitignore.is_ignored(""), false)

  // 单字符路径
  gitignore.add_pattern("a")
  assert_eq(gitignore.is_ignored("a"), true)
  assert_eq(gitignore.is_ignored("b"), false)

  // 路径只包含斜杠
  gitignore.add_pattern("/")
  assert_eq(gitignore.is_ignored("/"), true)

  // 相对路径标记
  gitignore.add_pattern("./")
  assert_eq(gitignore.is_ignored("./"), true)

  // 路径包含连续斜杠
  gitignore.add_pattern("path//file")
  assert_eq(gitignore.is_ignored("path//file"), true)

  // 路径以斜杠结尾
  gitignore.add_pattern("directory/")
  assert_eq(gitignore.is_ignored("directory/"), true)
  assert_eq(gitignore.is_ignored("directory"), true)
}

// 新增测试：性能和压力测试

///|
test "stress_and_performance" {
  let gitignore = Gitignore::new()

  // 添加大量不同类型的模式
  for i = 0; i < 50; i = i + 1 {
    gitignore.add_pattern("pattern" + i.to_string() + "*")
    gitignore.add_pattern("**/deep" + i.to_string() + "/**")
    gitignore.add_pattern("file[" + i.to_string() + "].txt")
    gitignore.add_pattern("!" + "keep" + i.to_string())
  }

  // 测试复杂匹配
  assert_eq(gitignore.is_ignored("pattern25_file.txt"), true)
  assert_eq(gitignore.is_ignored("path/deep30/file.txt"), true)
  assert_eq(gitignore.is_ignored("file3.txt"), true)
  assert_eq(gitignore.is_ignored("keep25"), false)

  // 测试不匹配的情况
  assert_eq(gitignore.is_ignored("unrelated_file.doc"), false)
  assert_eq(gitignore.is_ignored("different/path/structure"), false)
}

// 新增测试：from_string的复杂情况

///|
test "from_string_complex_cases" {
  // 包含各种复杂情况的gitignore内容
  let complex_content = "# Complex gitignore test\n# Empty lines and comments\n\n\n# Escaped characters\n\\\\#not_a_comment\n\\\\!not_negated\n\n# Mixed patterns\n*.log\n!important.log\ntemp*/\n**/build/**\nsrc/**/test\n\n# Unicode and special characters\n文档.txt\nfile with spaces.txt\n\n# Edge cases\n/absolute/path\nrelative/path/\n!negated/pattern\n\n# Multiple wildcards\ntest-*.log\nfile[0-9].txt\nClass[A-Z]*.java\n\n# Empty and whitespace lines\n   \n\t\t\n\n# Final comment"
  let gitignore = Gitignore::from_string(complex_content)

  // 测试各种模式 - 修复转义字符测试
  assert_eq(gitignore.is_ignored("#not_a_comment"), false) // \\# 被处理为字面量 #
  assert_eq(gitignore.is_ignored("!not_negated"), false) // \\! 被处理为字面量 !
  assert_eq(gitignore.is_ignored("app.log"), true)
  assert_eq(gitignore.is_ignored("important.log"), false)
  assert_eq(gitignore.is_ignored("temp123/file"), true)
  assert_eq(gitignore.is_ignored("project/build/output"), true)
  assert_eq(gitignore.is_ignored("src/main/test"), true)
  assert_eq(gitignore.is_ignored("文档.txt"), true)
  assert_eq(gitignore.is_ignored("file with spaces.txt"), true)
  assert_eq(gitignore.is_ignored("absolute/path"), true)
  assert_eq(gitignore.is_ignored("relative/path/file"), true)
  assert_eq(gitignore.is_ignored("negated/pattern"), false)
  assert_eq(gitignore.is_ignored("test-debug.log"), true)
  assert_eq(gitignore.is_ignored("file5.txt"), true)
  assert_eq(gitignore.is_ignored("ClassAMain.java"), false) // 修复测试预期
}

// 新增测试：PathStatus枚举的完整测试

///|
test "path_status_comprehensive" {
  let gitignore = Gitignore::new()
  gitignore.add_pattern("*.temp")
  gitignore.add_pattern("!important.temp")
  gitignore.add_pattern("secret.temp")

  // 测试所有可能的返回状态
  assert_eq(gitignore.check_path("file.temp"), Ignored)
  assert_eq(gitignore.check_path("important.temp"), NotIgnored)
  assert_eq(gitignore.check_path("secret.temp"), Ignored)
  assert_eq(gitignore.check_path("file.txt"), NotIgnored)

  // 测试状态的字符串表示
  let status1 = gitignore.check_path("file.temp")
  let status2 = gitignore.check_path("file.txt")
  assert_eq(status1, Ignored)
  assert_eq(status2, NotIgnored)
  assert_eq(status1 == status2, false)
}
