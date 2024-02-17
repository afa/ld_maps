class Page < Sequel::Model(:page)
  enum :status,
    prefix: true,
    init: 0,
    scaned: 1,
    checked: 2,
    saved: 3
end
