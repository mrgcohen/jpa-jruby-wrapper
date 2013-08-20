class Criteria
  DATA = Java::HarbingerSdkData
  SDK = Java::HarbingerSdk

  attr_accessor :builder, :criteria, :limit, :roots, :page, :select

  def sql
     @roots.collect{ |t,v| "table:#{t}: #{v.toString}"}
  end

  def initialize(em=nil)
    # confirm em exists
    em = handle_entity_manager(em)

    # get builder and startup
    @builder = em.getCriteriaBuilder()
    @criteria = @builder.createQuery()
    @roots = {}

    @limit = 0

    # stores from table
    @from = nil
    @from_table = nil

    # stores root conjunctions
    @conjunction = @builder.conjunction()
    @use_conjunction = false

    # stores root disjunctions
    @disjunction = @builder.disjunction()
    @use_disjunction = false

    self
  end

  # chaining methods

  # select from table
  def from(table_name)
    @from = @roots[table_name] = @criteria.from(eval("Java::Harbinger.sdk.data.#{table_name}.java_class"))
    @from_table = table_name
    @select = @criteria.select(@roots[table_name])

    self
  end

  # between 2 values as disjunction or conjunction (by default conjunction)
  def between(table, column, min, max, and_or="and")
    if and_or == "and"
      and_exp(@builder.between(@roots[table].get(column),min,max))
    else
      or_exp(@builder.between(@roots[table].get(column),min,max))
    end
    self
  end

  # equals only right now as a conjunction (default) or disjunction
  def where(table, column, value, and_or="and", ignore_case=false)
    if ignore_case
      return where_ignore_case(table, column, value, and_or)
    end
    if and_or == "and"
      and_exp(@builder.equal(@roots[table].get(column),value))
    else # or
      or_exp(@builder.equal(@roots[table].get(column),value))
    end
    self
  end

  # equals only right now as a conjunction (default) or disjunction
  def where_ignore_case(table, column, value, and_or="and")
    if and_or == "and"
      and_exp(@builder.equal(@builder.lower(@roots[table].get(column)),value.downcase))
    else # or
      or_exp(@builder.equal(@builder.lower(@roots[table].get(column)),value.downcase))
    end
    self
  end
  
  def is_not_null(table, column, and_or="and")
    if and_or == "and"
      and_exp(@builder.isNotNull(@roots[table].get(column)))
    else # or
      or_exp(@builder.isNotNull(@roots[table].get(column)))
    end
    self
  end
  
  def is_null(table, column, and_or="and")
    if and_or == "and"
      and_exp(@builder.isNull(@roots[table].get(column)))
    else # or
      or_exp(@builder.isNull(@roots[table].get(column)))
    end
    self
  end

  def gt(table,column,value, and_or="and")
    if and_or == "and"
      and_exp(@builder.gt(@roots[table].get(column),value))
    else
      or_exp(@builder.gt(@roots[table].get(column),value))
    end
  end

  def ge(table,column,value, and_or="and")
    if and_or == "and"
      and_exp(@builder.ge(@roots[table].get(column),value))
    else
      or_exp(@builder.ge(@roots[table].get(column),value))
    end
  end

  def lessThanOrEqualTo(*args)
    le(*args)
  end

  def lt(table,column,value, and_or="and")
    if and_or == "and"
      and_exp(@builder.lt(@roots[table].get(column),value))
    else
      or_exp(@builder.lt(@roots[table].get(column),value))
    end
  end

  def le(table,column,value, and_or="and")
    if and_or == "and"
      and_exp(@builder.le(@roots[table].get(column),value))
    else
      or_exp(@builder.le(@roots[table].get(column),value))
    end
  end

  # like where addition as as conjunction (default) or disjunction
  def like_ignore_case(table, column, value, and_or="and")
    if and_or == "and"
      and_exp(@builder.like(@builder.lower(@roots[table].get(column)),value.downcase))
    else
      or_exp(@builder.like(@builder.lower(@roots[table].get(column)),value.downcase))
    end
    self
  end

  # like where addition as as conjunction (default) or disjunction
  def like(table, column, value, and_or="and", ignore_case=false)
    return like_ignore_case(table,column,value,and_or) if ignore_case
    if and_or == "and"
      and_exp(@builder.like(@roots[table].get(column),value))
    else
      or_exp(@builder.like(@roots[table].get(column),value))
    end
    self
  end

  # add expression as disjunction (or)
  def or_exp(expression)
    @use_disjunction = true
    @disjunction = @builder.and(@disjunction,expression)

    self
  end

  # add expression as conjunction (and)
  def and_exp(expression)
    @use_conjunction = true
    @conjunction = @builder.and(@conjunction,expression)

    self
  end

  # join (fetch) more tables (default to inner join, use "left" for outer)
  def join(table,from=nil,type="inner")
    from = @from_table if from.nil?
    case type
    when "left"
      @roots[table] = @roots[from].join(table, Java::javax.persistence.criteria.JoinType::LEFT)
    else
      # default to inner join
      @roots[table] = @roots[from].join(table)
    end

    self
  end

  # where for in list
  def in(table,column,list,and_or="and")
    if and_or == "and"
      @use_conjunction = true
      @conjunction = @builder.and(@conjunction,@builder.in(@roots[table].get(column),list))
    else # or
      @use_disjunction = true
      @disjunction = @builder.and(@disjunction,@builder.in(@roots[table].get(column),list))
    end
    self
  end

  # add orderby clause
  def order(table_name,column,desc_or_asc="asc")
    if desc_or_asc == "desc"
      @criteria.orderBy(@builder.desc(@roots[table_name].get(column)))
    else
      @criteria.orderBy(@builder.asc(@roots[table_name].get(column)))
    end
    self
  end

  # setup paging
  def page(page,per_page)
    @criteria.setFirstResult(page.to_i*per_page.to_i)
    self
  end

  # set a limit, optional pass in paging settings
  def limit(per_page,page=0)
    @limit = per_page
    @page = page

    self
  end

  # return results of query and close local entity managers
  def list(raw=false)
    begin
      @criteria.where(@builder.and(@conjunction)) if @use_conjunction
      @criteria.where(@builder.or(@disjunction)) if @use_disjunction

      query = @em.createQuery(@criteria)

      # set page if set
      if @page and @limit
        query.setFirstResult(@page.to_i*@limit)
      else
        query.setFirstResult(@page.to_i || 0)
      end

      # set limit if exists
      if @limit
        query.setMaxResults(@limit)
      end

      # show raw arraylist or ruby array
      result = query.getResultList()
      unless raw
        result = result.to_a
      end
      
      # close if needed
      @em.close if @em_local
    rescue Exception => e
      @em.close if @em_local
      throw e
    end
    return result
  end

  # get an entity manager if need one
  def self.em
    Java::HarbingerSdk::DataUtils.getEntityManager()
  end

  def close_em
    begin
      @em.close
    rescue
      # just try catch failure
    end
  end

  protected

  # get em if doesn't exist and set em as local
  def handle_entity_manager(em)
    unless em
      em = Criteria.em
      @em_local = true
    else
      @em_local = false
    end
    @em = em
  end

end
