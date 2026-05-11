# Skill Cold Library — Agent Skill 冷热分层管理

## 问题

当你装了 200+ 个 Agent Skills，即使每个只加载一行概括描述也消耗大量 token，常见 Skill 系统的渐进式披露根本不够用——描述本身就在吃上下文。不常用的框架、语言、行业知识类 Skill 没必要常驻。

## 方案：把不常用的放进"冷库"，按需激活

```
活跃 (~60)：自动加载
冷库 (~170)：不加载，通过一个"图书管理员"skill 按需搜索、激活、用完放回
```

```
.agents/
├── skills/              # 活跃技能，自动加载
│   └── skill-library/   # 图书管理员（唯一新增的）
└── skill-libraries/     # 冷库，不加载
    ├── tools/
    ├── knowledge/
    ├── dev-frameworks/
    ├── industry-domain/
    ├── media-content/
    └── agent-ops/
```

## 用的时候

```powershell
# 1. 搜索
search-library.ps1 -Query "jira"
# 2. 查看
inspect-skill.ps1 -Name "jira-integration"
# 3. 激活（符号链接到活跃目录）
activate-skill.ps1 -Name "jira-integration"
# 4. 用完放回
deactivate-skill.ps1 -Name "jira-integration"
```

## 为什么不是渐进式披露的问题

常见做法是 Skill 只在触发时加载正文，但 200+ 个 Skill 的概括描述本身就占 ~17K token。冷库方案让不常用的技能连描述都不出现在上下文里。

## 安装

```powershell
git clone https://github.com/shenyiqi-2004/skill-library.git ~/.agents/skills/skill-library
mkdir ~/.agents/skill-libraries/{tools,knowledge,dev-frameworks,industry-domain,media-content,agent-ops}
# 把不常用的技能移入对应分类
~/.agents/skills/skill-library/scripts/rebuild-catalog.ps1
```

## License

MIT
