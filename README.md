jpa-jruby-wrapper
=================

Wrap the jpa calls with jruby

# Overview

This is my initial stab.. sort of hacked together to work.  Probably should be made better but just needed something to start with

It should automatically create em and close it when query is complete or you can pass it an em to use on init. Passing the em is preferred. 

## Examples

### Latest Version can now do joins with multiple tables and optionally get the count instead of the results

```bash
jruby-1.6.8 :194 > @audit = {}
jruby-1.6.8 :195 > a = Crit.new(em,audit).from("RadExam",:count => true)
                          .joins("currentStatus.tripStatus")
                          .where("tripStatus","status","prelim")
                          .joins("radExamTime")
                          .between("radExamTime","endExam",Time.now-2.years,Time.now-7.days)
                          .list
jruby-1.6.8 :196 > # Pass @audit directly to audit method in usual sdk 
                          
 => 9382 
```

### More Examples

```ruby

@new_crit = Criteria.new.from("Table")
                          .join("table2")
                          .join("table3")
                          .where("table1","column",value)
                          .limit(30).list
                          
# or pass it an entity_manager
entity_manager = Criteria.em
Criteria.new(entity_manager).from("Table")
                          
@query = Criteria.new.from("Table")
@query.in("Table","column",list)

# return ruby array
@results = @query.list

# return java object or array
@results = @query.list(true)

                          
# use tojson
@radExams.collect{|e| e.rad_exam_to_json(e)}
```
