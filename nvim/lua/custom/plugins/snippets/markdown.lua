local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require("luasnip.util.events")
local ai = require("luasnip.nodes.absolute_indexer")
local extras = require("luasnip.extras")
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local conds = require("luasnip.extras.expand_conditions")
local postfix = require("luasnip.extras.postfix").postfix
local types = require("luasnip.util.types")
local parse = require("luasnip.util.parser").parse_snippet

-- snippet for underline text
ls.add_snippets("markdown", {
  s("underline", {
    t({ "<u>" }),
    i(1),
    t({ "</u>" })
  })
})

-- snippet for comment
ls.add_snippets("markdown", {
  s("comment", {
    t({ "%" }),
    i(1),
    t({ "%" })
  })
})

-- todos
ls.add_snippets("markdown", {
  s("todo", {
    t({ "- [ ] " }),
    i(1),
  })
})

ls.add_snippets("markdown", {
  s("todo incomplete", {
    t({ "- [/] " }),
    i(1),
  })
})

ls.add_snippets("markdown", {
  s("todo done", {
    t({ "- [x] " }),
    i(1),
  })
})

ls.add_snippets("markdown", {
  s("todo cancled", {
    t({ "- [-] " }),
    i(1),
  })
})

ls.add_snippets("markdown", {
  s("todo forwarded", {
    t({ "- [>] " }),
    i(1),
  })
})

ls.add_snippets("markdown", {
  s("todo scheduling", {
    t({ "- [<] " }),
    i(1),
  })
})

ls.add_snippets("markdown", {
  s("todo question", {
    t({ "- [?] " }),
    i(1),
  })
})


ls.add_snippets("markdown", {
  s("todo important", {
    t({ "- [!] " }),
    i(1),
  })
})

ls.add_snippets("markdown", {
  s("code block", {
    t({ "```",
      " ",
      "```"
    }),
  })
})
