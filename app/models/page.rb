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
         name_validated: 6,
         stored: 7,
         invalid_name: 8, # invalid states
         invalid_file: 9,
         failed: 10
       },
       prefix: true
end
