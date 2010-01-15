module MethodFaker
  def self.extended(klass)
    class << klass
      def faked_methods
        @faked_methods ||= { }
      end
    end
  end
  def fake(method_name, proc = nil, &block)
    fail 'You can\'t fake that' if (method_name =~ /__|instance_eval/)
    faked_methods[method_name] ||= inquire_method(method_name)
    if proc && block
      block_fake(method_name, proc, block)
    else
      standard_fake(method_name, proc || block)
    end
  end
  def restore(method_name)
    fail 'Can\'t restore a not faked method' unless faked? method_name
    define_method_with_visibility method_name, *faked_methods.delete(method_name)
  end
  def faked?(method_name)
    faked_methods.keys.include? method_name
  end
  def inquire_method(method_name)
    return [instance_method(method_name), :public] if public_instance_methods.include? method_name
    return [instance_method(method_name), :protected] if protected_instance_methods.include? method_name
    return [instance_method(method_name), :private] if private_instance_methods.include? method_name
    fail '#{method_name} it\'s not a method in class: #{self}'
  end

private
  def block_fake(method_name, proc, block)
    standard_fake(method_name, proc)
    block.call
  ensure
    restore(method_name)
  end

  def standard_fake(method_name, block)
    visibility = faked_methods[method_name].last
    define_method_with_visibility method_name, block, visibility
  end

  def define_method_with_visibility(method_name, method, visibility)
    define_method method_name, method
    send visibility, method_name
  end
end

