module Format

  # return "" on nil response from harbinger
  def d(&block)
    begin
      yield
    rescue
      ""
    end
  end

  # show as time
  def self.to_time(datetime)
    begin
      Time.parse(datetime.to_s).strftime("%T")
    rescue
      ""
    end
  end
  # show as date
  def self.to_date(datetime)
    begin
      Time.parse(datetime.to_s).strftime("%m/%e/%Y")
    rescue
      ""
    end
  end
  # clean up name
  def self.clean_user_name(name)
    name = name.split("^").each(&:capitalize!).join(" ")
  end

  def self.clean_patient_name(name)
    name = name.split("^").each(&:capitalize!)
    [name.first.strip,", ",name.slice(1,name.size-1).join(" ")].join
  end

  def self.firstname(name)
    name = name.split("^").each(&:capitalize!)
    name.slice(1)
  end

  def self.middle(name)
    name = name.split("^").each(&:capitalize!)
    if name.size > 2
      [name.slice(2,name.size-1).join(" ")].join
    else
      ""
    end
  end

  def self.lastname(name)
    name = name.split("^").each(&:capitalize!)
    name.first.strip
  end

end
