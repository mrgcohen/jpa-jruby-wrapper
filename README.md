jpa-jruby-wrapper
=================

Wrap the jpa calls with jruby

# Overview

This is my initial stab.. sort of hacked together to work.  Probably should be made better but just needed something to start with

It should automatically create em and close it when query is complete or you can pass it an em to use on init. Passing the em is preferred. 

## Examples
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

# another example
@radExams = Criteria.new(entity_manager).from("RadExam")
                          .join("radExamTime")
                          .join("radExamPersonnel")
                          .join("ordering","radExamPersonnel")
                          .where("ordering","id",ordering_id)
                          .limit(10)
                          .order("radExamTime","endExam","desc")
                          .list
                          
# re-write in dot notation
@radExams = Criteria.new(entity_manager).from("RadExam")
                          .join("radExamTime")
                          .join("radExamPersonnel.ordering")
                          .where("ordering","id",ordering_id)
                          .limit(10)
                          .order("radExamTime","endExam","desc")
                          .list
                          
# another example for between
@radExams = Criteria.new(em).from("RadExam")
                          .join("radExamTime")
                          .between("radExamTime","endExam",Time.parse(startTime),Time.parse(endTime))
                          .list
                          
# use tojson
@radExams.collect{|e| e.rad_exam_to_json(e)}
```
