require 'spec_helper'

describe ActiveRecord do
  it 'should load classes with non-default primary key' do
    lambda {
      YAML.load(Story.create.to_yaml)
    }.should_not raise_error    
  end

  it 'should load classes even if not in default scope' do
    lambda {
      YAML.load(Story.create(:scoped => false).to_yaml)
    }.should_not raise_error    
  end
  
  it 'should load saved classes containing transient attributes' do
    lambda {
      class Story
        has_one :villan
        attr_accessor :transient_attr1
        attr_accessor :transient_attr2
      end
      
      YAML.parser.class.name.should match(/psych/i)

      s_saved = Story.create(:text => 'value')
      s_saved.transient_attr1 = 'transvalue'
      s_saved.should respond_to(:encode_with)
    
      # Add association
      villan = s_saved.create_villan(:name => 'badguy')
      
      # Serialize
      y = s_saved.to_yaml
      
      y.should     match(/ActiveRecord:Story/)
      y.should     match(/attributes:/)
      y.should     match(/text: value/)
      y.should     match(/scoped: true/)
      y.should     match(/story_id:/)
      y.should     match(/transient_attr1.*transvalue/)
      y.should_not match(/transient_attr2/)
      y.should_not match(/villan/)

      # Deserialize
      s2 = YAML.load(y)
      s2.should_not be_nil
      s2.should be_a(Story)
      s2.transient_attr1.should == 'transvalue'
      s2.transient_attr1.should == s_saved.transient_attr1
      
      s2.text.should == s_saved.text
      s2.scoped.should == s_saved.scoped
      s2.should == s_saved
      
      s2.villan.name.should == villan.name
      s2.villan.should == villan
      
      # Finding the original object should not have its transient attribute
      s3 = Story.find(s_saved.id)
      s3.text.should == s_saved.text
      s3.scoped.should == s_saved.scoped
      s3.transient_attr1.should be_nil
      
    }.should_not raise_error    
    end

  it 'should load unsaved classes containing transient attributes' do
    lambda {
      class Story
        has_one :villan
        attr_accessor :transient_attr1
        attr_accessor :transient_attr2
      end
      
      YAML.parser.class.name.should match(/psych/i)

      s_unsaved = Story.new(:text => 'value')
      s_unsaved.transient_attr1 = 'transvalue'
      s_unsaved.should respond_to(:encode_with)
      
      # Add association
      villan = s_unsaved.build_villan(:name => 'badguy')
      
      # Serialize
      y = s_unsaved.to_yaml
      
      y.should     match(/ActiveRecord:Story/)
      y.should     match(/attributes:/)
      y.should     match(/text: value/)
      y.should     match(/scoped: true/)
      y.should     satisfy {|yaml| yaml !~ /story_id:/ || yaml =~ /story_id.*null/}
      y.should     match(/transient_attr1.*transvalue/)
      y.should_not match(/transient_attr2/)
      y.should_not match(/villan/)

      # Deserialize
      lambda {YAML.load(y)}.should raise_exception(Delayed::DeserializationError)
            
    }.should_not raise_error    
    end

  it 'should roundtrip through delayed job' do
    lambda {
      class Story
        def perform
        end
      end
      
      s = Story.create(:scoped => false)
      y1 = s.to_yaml

      dj = Delayed::Job.enqueue s
      y2 = dj.payload_object.to_yaml
      y2.should == y1
      
      y3 = dj.to_yaml
      y3.should_not match(/payload_object/)
      

    }.should_not raise_error    
  end
end
