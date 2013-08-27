class Criteria
  DATA = Java::HarbingerSdkData
  SDK = Java::HarbingerSdk
  FROM = "Java::Harbinger.sdk.data"
  DU = Java::HarbingerSdk::DataUtils

  attr_accessor :builder, :criteria, :limit, :roots, :page, :select, :alias, :from_table, :from, :disjunction, :conjunction

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

    # alias defaults to basic hash
    @alias = {}

    self
  end

  # chaining methods

  # select from table
  def from(table_name, options = {})
    options[:alias] ||= table_name

    # add to roots
    @roots[table_name] = @criteria.from(eval("#{FROM}.#{table_name}.java_class"))

    # set from
    @from = @roots[table_name]

    # set alias for both
    @alias[options[:alias]] = @roots[table_name]
    @alias[table_name] = @roots[table_name]

    # set table name for from
    @from_table = table_name

    @select = @criteria.select(@roots[table_name])

    self
  end

  # between 2 values as disjunction or conjunction (by default conjunction)
  def between(table, column, min, max, and_or="and")
    if and_or == "and"
      and_exp(@builder.between(@alias[table].get(column),min,max))
    else
      or_exp(@builder.between(@alias[table].get(column),min,max))
    end
    self
  end

  def not(method,*options)
    self.send(method, options)
  end

  # equals only right now as a conjunction (default) or disjunction
  def where(table, column, value, and_or="and", ignore_case=false)
    if ignore_case
      return where_ignore_case(table, column, value, and_or)
    end
    if and_or == "and"
      and_exp(@builder.equal(@alias[table].get(column),value))
    else # or
      or_exp(@builder.equal(@alias[table].get(column),value))
    end
    self
  end

  # equals only right now as a conjunction (default) or disjunction
  def where_ignore_case(table, column, value, and_or="and")
    if and_or == "and"
      and_exp(@builder.equal(@builder.lower(@alias[table].get(column)),value.downcase))
    else # or
      or_exp(@builder.equal(@builder.lower(@alias[table].get(column)),value.downcase))
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
      and_exp(@builder.gt(@alias[table].get(column),value))
    else
      or_exp(@builder.gt(@alias[table].get(column),value))
    end
  end

  def ge(table,column,value, and_or="and")
    if and_or == "and"
      and_exp(@builder.ge(@alias[table].get(column),value))
    else
      or_exp(@builder.ge(@alias[table].get(column),value))
    end
  end

  def lessThanOrEqualTo(*args)
    le(*args)
  end

  def lt(table,column,value, and_or="and")
    if and_or == "and"
      and_exp(@builder.lt(@alias[table].get(column),value))
    else
      or_exp(@builder.lt(@alias[table].get(column),value))
    end
  end

  def le(table,column,value, and_or="and")
    if and_or == "and"
      and_exp(@builder.le(@alias[table].get(column),value))
    else
      or_exp(@builder.le(@alias[table].get(column),value))
    end
  end

  # like where addition as as conjunction (default) or disjunction
  def like_ignore_case(table, column, value, and_or="and")
    if and_or == "and"
      and_exp(@builder.like(@builder.lower(@alias[table].get(column)),value.downcase))
    else
      or_exp(@builder.like(@builder.lower(@alias[table].get(column)),value.downcase))
    end
    self
  end

  # like where addition as as conjunction (default) or disjunction
  def like(table, column, value, and_or="and", ignore_case=false)
    return like_ignore_case(table,column,value,and_or) if ignore_case
    if and_or == "and"
      and_exp(@builder.like(@alias[table].get(column),value))
    else
      or_exp(@builder.like(@alias[table].get(column),value))
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

  # provides dot notation for join
  # joins("patientMrn.patient") now instead of join("patientMrn").join("patient",:from=>"patientMrn")
  def joins(tables,options={})
    # now check for dot notiation
    dot_notation = tables.split "."
    parent_table = nil
    options = {}
    dot_notation.each do |j_table|
      options[:from] = parent_table unless parent_table.nil?
      options[:alias] = j_table unless parent_table.nil?
      puts "join("+j_table+","+options.inspect+")"
      join(j_table,options)
      parent_table = j_table
    end

    self
  end

  # join (fetch) more tables (default to inner join, use "left" for outer)
  def join(table,options={})
    # defaults
    options[:type] ||= "inner"
    options[:alias] ||= table
    options[:from] ||= @from_table

    case options[:type]
    when "left"
      @roots[table] = @alias[options[:from]].join(table, Java::javax.persistence.criteria.JoinType::LEFT)
    else
      # default to inner join
      @roots[table] = @alias[options[:from]].join(table)
    end

    # set alias
    # @alias[options[:from]] = @roots[table]
    @alias[options[:alias]] = @roots[table]
    @alias[table] = @roots[table]

    self
  end

  # where for in list
  def in(table,column,list,and_or="and")
    if and_or == "and"
      @use_conjunction = true
      @conjunction = @builder.and(@conjunction,@builder.in(@alias[table].get(column),list))
    else # or
      @use_disjunction = true
      @disjunction = @builder.and(@disjunction,@builder.in(@alias[table].get(column),list))
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
    DU.getEntityManager()
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
