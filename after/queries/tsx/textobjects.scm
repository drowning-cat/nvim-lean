;; extends

(jsx_element open_tag: (_) (_)+ @tag.inner close_tag: (_)) @tag.outer
(jsx_element
  open_tag: (jsx_opening_element
    name: (identifier) @tag_name.outer
    _* @tag_name.inner
  )
  _+ @tag_name.inner
  close_tag: (jsx_closing_element
    _* @tag_name.inner
    name: (identifier) @tag_name.outer
  )
)
