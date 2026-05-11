# Skill Cold Library

## 问题

当你装了 200+ 个 Agent Skills，即使每个只加载一行描述也消耗大量 token。渐进式披露不够用——不常用和知识类的 Skill 连描述都不该进上下文。

## 方案：冷热分层

- **热层**（活跃技能）：日常高频使用，自动加载
- **冷层**（冷库）：不常用/知识类，不加载。通过一个"图书管理员"Skill 按需搜索、激活、用完放回

```
.agents/
├── skills/              # 热层，自动加载
│   └── skill-library/   # 图书管理员（冷层唯一入口）
└── skill-libraries/     # 冷层，不加载，按分类组织
    ├── tools/           # CLI、API、外部服务
    ├── knowledge/       # 研究、规划、文档
    ├── dev-frameworks/  # 语言、框架、数据库
    ├── industry-domain/ # 行业、合规、金融
    ├── media-content/   # 写作、SEO、视频
    └── agent-ops/       # 自主Agent、评估、编排
```

## 使用

```powershell
# 搜索冷库
search-library.ps1 -Query "jira"

# 查看匹配结果
inspect-skill.ps1 -Name "jira-integration"

# 激活（符号链接到热层）
activate-skill.ps1 -Name "jira-integration"

# 用完后放回冷库
deactivate-skill.ps1 -Name "jira-integration"
```

## 为什么不做渐进式披露

渐进式披露只解决"不触发就不加载正文"，但所有 Skill 的描述仍然在上下文中。200 个 Skill 的描述就要 ~17K token。冷库方案让不常用的 Skill 连描述都不出现。

## 安装

```powershell
git clone https://github.com/shenyiqi-2004/skill-library.git ~/.agents/skills/skill-library

# 创建冷库分类目录
mkdir ~/.agents/skill-libraries/{tools,knowledge,dev-frameworks,industry-domain,media-content,agent-ops}

# 把不常用的 Skill 移入对应分类，然后重建索引
~/.agents/skills/skill-library/scripts/rebuild-catalog.ps1
```

## 适用场景

- Skill 数量 > 100，描述已占上下文 1%+
- 大量框架/语言/行业 Skill 不常用但偶尔需要
- 不想删，希望按需取用

## License

MIT
