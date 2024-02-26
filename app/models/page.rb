class Page < Sequel::Model(:page)
  plugin :enum

  enum :state,
       {
         init: 0,        # pages states
         scaned: 1,
         checked: 2,
         saved: 3,
         waiting: 4,     # files states
         validating: 5,
         stored: 6
       },
       prefix: true
end
