class Page < Sequel::Model(:page)
  plugin :enum

  enum :state,
       prefix: true,
       init: 0,
       scaned: 1,
       checked: 2,
       saved: 3
end
