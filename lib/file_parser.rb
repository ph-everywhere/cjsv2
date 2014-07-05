class CJSVFileParser
  def initialize(file_name)
    @coffee_indent = 0
    @cjsv_indent = 0

    @function_name = CJSVFileParser.function_name_by_file file_name

    @lines = File.open(file_name, "rb").read.split "\n"
    @current_line = 0

    sanitize_and_verify
    parse
  end

  def body
    @function_body
  end

  def name
    @function_name
  end

  def sanitize_and_verify()
    @spaces_per_indent = 2
    @lines = @lines.reject{|line| line =~ /^\s*$/}.map { |line|
      line.split('-#')[0].rstrip # Remove comment lines and trailing whitespace
    }.reject{|line| line =~ /^\s*$/} # Reject empty lines
  end

  def parse()
    @parsed_lines = []

    @lines.each do |line|
      parsed_line = CJSVLineParser.new(line, @spaces_per_indent)

      if parsed_line.type == 'CSV_ARGS_LINE'
        @arguments_line = parsed_line
      else
        @parsed_lines << parsed_line
      end
    end

    generate_function_body
  end

  def generate_function_body
    @function_body = "\n"
    @function_body += ' '*@spaces_per_indent+'  _outstream=""'+"\n"

    @unclosed_tags = []

    @parsed_lines.each do |parsed_line|
      while @unclosed_tags.length > 0 and @unclosed_tags.last.indentation >= parsed_line.indentation
        @function_body += output_line @unclosed_tags.pop.close
      end

      @function_body += output_line parsed_line.html

      @unclosed_tags << parsed_line unless parsed_line.is_self_enclosed_tag?
    end

    while @unclosed_tags.length > 0
      @function_body += output_line @unclosed_tags.pop.close
    end
  end

  def output_line(html)
    "\n  "+' '*(@spaces_per_indent)+'_oustream += "'+html+'"'
  end

  def self.function_name_by_file(file_name)
    file_name.split('/').last.gsub(/.cjsv$/, '')+': () ->'
  end
end