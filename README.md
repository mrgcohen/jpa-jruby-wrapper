jpa-jruby-wrapper
=================

Wrap the jpa calls with jruby

# Overview

This is my initial stab.. sort of hacked together to work.  Probably should be made better but just needed something to start with

It should automatically create em and close it when query is complete or you can pass it an em to use on init

## Examples
```ruby

@new_crit = Criteria.new.from("Table")
                          .join("table2")
                          .join("table3")
                          .where("table1","column",value)
                          .limit(30).list
                          
# or pass it an entity_manager
# Criteria.new(entity_manager).from("Table")
                          
@query = Criteria.new.from("Table")
@query.in("Table","column",list)

# return ruby array
@results = @query.list

# return java object or array
@results = @query.list(true)
```
