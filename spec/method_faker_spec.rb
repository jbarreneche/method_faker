require File.expand_path(File.dirname(__FILE__) + '/../lib/method_faker')

describe "Classes wich extend MethodFaker" do
  before(:each)do
    @class = create_basic_class
    @object = @class.new
    @class.send :extend, MethodFaker
  end
  context 'faking a method' do
    context 'public' do
      before(:each) do
        @class.fake(:some_public_method) { false }
      end
      it 'should replace public method with the given block' do
        @object.some_public_method.should be_false
        @class.instance_methods.should include(:some_public_method)
      end
      it 'should not touch methods in the module' do
        MethodFaker.methods.should_not include(:some_public_method)
      end
      it 'should identified the method as faked' do
        @class.should be_faked(:some_public_method)
      end
    end
    # Avoid the use of send for public methods, thus not included in this meta-test
    [:private, :protected].each do |visibility|
      context visibility do
        before(:each) do
          @method_name = :"some_#{visibility}_method"
          @object.send(@method_name).should be_true
          @class.fake(@method_name) { false }
        end
        it "should replace #{visibility} method with the given block" do
          @object.send(@method_name).should be_false
          @class.send(:"#{visibility}_instance_methods").should include(@method_name)
        end
        it 'should not touch methods in the module' do
          MethodFaker.methods.should_not include(@method_name)
        end
        it 'should identified the method as faked' do
          @class.should be_faked(@method_name)
        end
      end
    end
  end
  context 'restoring a method' do
    context 'public' do
      before(:each) do
        @class.fake(:some_public_method) { false }
        @class.restore(:some_public_method)
      end
      it 'should restore public method with the given block' do
        @object.some_public_method.should be_true
        @class.instance_methods.should include(:some_public_method)
      end
      it 'should not touch methods in the module' do

        MethodFaker.methods.should_not include(:some_public_method)
      end
      it 'should not identified the method as faked' do
        @class.should_not be_faked(:some_public_method)
      end
    end
    # Avoid the use of send for public methods, thus not included in this meta-test
    [:private, :protected].each do |visibility|
      context visibility do
        before(:each) do
          @method_name = :"some_#{visibility}_method"
          @class.fake(@method_name) { false }
          @class.restore(@method_name)
        end
        it "should restore #{visibility} method with the given block" do
          @object.send(@method_name).should be_true
          @class.send(:"#{visibility}_instance_methods").should include(@method_name)
        end
        it 'should not touch methods in the module' do
          MethodFaker.methods.should_not include(@method_name)
        end
        it 'should not identified the method as faked' do
          @class.should_not be_faked(@method_name)
        end
      end
    end
  end
  context 'faking an unexisting method' do
    it 'should raise exception' do
      lambda {
        @class.fake(:some_unexisting_method)
      }.should raise_error RuntimeError
    end
  end
  context 'faking an alredy faked method' do
    before(:each) do
      @class.fake(:some_public_method) { 1 }
      @class.fake(:some_public_method) { 2 }
    end
    it 'should redefine the alredy faked method' do
      @object.some_public_method.should == 2
    end
    it 'should restore the original' do
      @class.restore(:some_public_method)
      @object.some_public_method.should be_true
    end
  end
  context 'restoring a not faked method' do
    it 'should raise exception when the method was never faked' do
      lambda {
        @class.restore(:some_public_method)
      }.should raise_error RuntimeError
    end
    it 'should raise exception when the method is restored twice' do
      @class.fake(:some_public_method) { false }
      @class.restore(:some_public_method)
      lambda {
        @class.restore(:some_public_method)
      }.should raise_error RuntimeError
    end
  end
  context 'context safe faking' do
    it 'should only use faked method within given block' do
      object = @object
      klass = @class
      @class.fake :some_public_method, lambda { false } do
        object.some_public_method.should be_false
        klass.should be_faked(:some_public_method)
      end
      object.some_public_method.should be_true
      klass.should_not be_faked(:some_public_method)
    end
    it 'should restore even if an exception it\'s thrown' do
      begin
        klass = @class
        @class.fake :some_public_method, lambda { false } do
          klass.should be_faked(:some_public_method)
          fail 'Fatal error!'
          true.should be_false
        end
        true.should be_false
      rescue
      end
      klass.should_not be_faked(:some_public_method)
    end
  end
end
def create_basic_class
  Class.new do
    def some_public_method
      true
    end
    def some_protected_method
      true
    end
    def some_private_method
      true
    end
    protected :some_protected_method
    private :some_private_method
  end
end

