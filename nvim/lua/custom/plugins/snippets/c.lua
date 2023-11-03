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

-- snippet for header include guard
ls.add_snippets("c", {
  s("include guard", {
    t({ "#pragma once" })
  })
})

---
-- snippets for doxygen documentation
---

-- function documentation
ls.add_snippets("c", {
  s("doxy func", {
    t({ "/*!",
      " * @brief\t",
      " * ",
      " * @details",
      " * ",
      " * @param",
      " * ",
      " * @returns",
      "**/"
    }),
  })
})

-- varaible documentation
ls.add_snippets("c", {
  s("doxy var after", {
    t({ "/*!< " }),
    i(1),
    t({ " */" })

  })
})


-- standard main function
ls.add_snippets("c", {
  s("main function", {
    t({ "int main(int argc, char* argv[]) { return 0; }" })
  })
})

-- simple comment
ls.add_snippets("c", {
  s("cmt", {
    t({ "/* " }),
    i(1),
    t({ " */" })
  })
})
