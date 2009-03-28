	  module Acts #:nodoc: 
	    module Hidden #:nodoc: 

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def acts_as_hidden(options={})
            unless hidden?  # don't let AR call it twice
              class << self
                alias_method  :find_every_with_hidden,  :find_every                          
              end
            end
            include InstanceMethods
          end

          def hidden?
            self.included_modules.include?(InstanceMethods)
          end
        end

        module InstanceMethods  #:nodoc:
          def set_visible
            self.visible = true
            self.passphrase = nil
            self.save
            self.after_unhiding if self.respond_to?(:after_unhiding)
          end

          def set_invisible
            self.visible = false
            self.passphrase =  Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join ) 
            self.save
            self.after_hiding if self.respond_to?(:after_hiding)
          end

          def self.included(base) #:nodoc:
            base.extend ClassMethods  
          end

          module ClassMethods

            def validate_find_options(options)
              options.assert_valid_keys [:page, :conditions, :include, :joins, :limit, :offset, :order, :select, :readonly, :group, :with_hidden, :from]
            end

            def find_any(id)  # Hidden or non hidden
              begin
                find(id)
              rescue ActiveRecord::RecordNotFound
                find(id,:with_hidden=>true)
              end
            end

            def find_with_hidden(*args)
              options = args.extract_options!
              validate_find_options(options)
              set_readonly_option!(options)
              options[:with_hidden] = true # yuck!

              case args.first
                when :first then find_initial(options)
                when :all   then find_every(options)
                else             find_from_ids(args, options)
              end
            end

            protected
            def with_hidden_scope(&block)
              with_scope({:find => { :conditions => ["#{table_name}.visible IS true"]}}, :merge, &block)
            end

            
            def find_every(options)
              puts("#{options[:conditions]}")
              options.delete(:with_hidden) ? find_every_with_hidden(options) :
                with_hidden_scope { find_every_with_hidden(options) }
            end
          end
  
        end

      end
    end
      
