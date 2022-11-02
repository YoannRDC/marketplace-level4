class ValidationError


    def initialize()
        @errors = Array.new
     end

    def is_valid()
        return @errors.empty?()
    end

    def contains_errors()
        return !@errors.empty?()
    end

    def add_string(error_msg)
        @errors.push(error_msg)
    end

    def add_ve(ve)
        ve.get_errors.each do |error_msg|
            @errors.push(error_msg)
        end
    end

    def get_errors()
        return @errors
    end

  end
  