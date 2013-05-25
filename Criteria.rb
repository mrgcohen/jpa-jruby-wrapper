class Criteria
  DATA = Java::HarbingerSdkData
  SDK = Java::HarbingerSdk

  attr_accessor :builder, :criteria, :limit, :roots

  def initialize(em=nil)
    # confirm em exists
    handle_entity_manager(em)

    # get builder and startup
    @builder = em.getCriteriaBuilder()
    @criteria = @builder.createQuery()
    @roots = {}

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
    @criteria.select(@roots[table_name])
    self
  end

  # between 2 values as disjunction or conjunction (by default conjunction)
  def between(table, column, min, max, and_or="and")
    if and_or == "and"
      @conjunction = @builder.between(@roots[table].get(column),min,max)
    else
      @disjunction = @builder.between(@roots[table].get(column),min,max)
    end
    self
  end

  # equals only right now as a conjunction (default) or disjunction
  def where(table, column, value, and_or="and")
    if and_or == "and"
      @use_conjunction = true
      @conjunction = @builder.and(@conjunction,@builder.equal(@roots[table].get(column),value))
    else # or
      @use_disjunction = true
      @disjunction = @builder.and(@disjunction,@builder.equal(@roots[table].get(column),value))
    end
    self
  end

  # like where addition as as conjunction (default) or disjunction
  def like(table, column, value, and_or="and")
    if and_or == "and"
      and_exp(@builder.like(@roots[table].get(column),value))
    else
      or_exp(@builder.like(@roots[table].get(column),value))
    end
  end

  # add expression as disjunction (or)
  def or_exp(expression)
    @use_disjunction = true
    @disjunction = @builder.and(@disjunction,expression)
  end

  # add expression as conjunction (and)
  def and_exp(expression)
    @use_conjunction = true
    @conjunction = @builder.and(@conjunction,expression)
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
    @limit = num
    page(page,per_page) if page > 0
    self
  end

  # return results of query and close local entity managers
  def list(raw=false)
    begin
      @criteria.where(@builder.and(@conjunction)) if @use_conjunction
      @criteria.where(@builder.or(@disjunction)) if @use_disjunction
      if raw
        result = @em.createQuery(@criteria).setMaxResults(20).getResultList()
      else
        result = @em.createQuery(@criteria).setMaxResults(20).getResultList().to_a
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
    SDK::DataUtils.getEntityManager()
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
