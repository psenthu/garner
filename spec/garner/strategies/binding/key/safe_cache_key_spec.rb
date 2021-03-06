require "spec_helper"

describe Garner::Strategies::Binding::Key::SafeCacheKey do

  before(:each) do
    @new_mock = double("model")
    @new_mock.stub(:cache_key) { "mocks/4" }
    @persisted_mock = double("model")
    @time_dot_now = Time.now
    @persisted_mock.stub(:cache_key) { "mocks/4-#{@time_dot_now.utc.to_s(:number)}" }
    @persisted_mock.stub(:updated_at) { @time_dot_now }
  end

  subject { Garner::Strategies::Binding::Key::SafeCacheKey }

  it_behaves_like "Garner::Strategies::Binding::Key strategy" do
    let(:known_bindings) { [@persisted_mock] }
    let(:unknown_bindings) { [@new_mock] }
  end

  describe "apply" do
    it "returns the object's cache key + milliseconds if defined" do
      timestamp = @time_dot_now.utc.to_s(:number)
      subject.apply(@persisted_mock).should =~ /^mocks\/4-#{timestamp}.[0-9]{10}$/
    end

    it "returns nil if :cache_key is undefined or nil" do
      @persisted_mock.unstub(:cache_key)
      subject.apply(@persisted_mock).should be_nil
      @persisted_mock.stub(:cache_key) { nil }
      subject.apply(@persisted_mock).should be_nil
    end

    it "returns nil if :updated_at is undefined or nil" do
      @persisted_mock.unstub(:updated_at)
      subject.apply(@persisted_mock).should be_nil
      @persisted_mock.stub(:updated_at) { nil }
      subject.apply(@persisted_mock).should be_nil
    end
  end

  context "with real objects" do
    before(:each) do
      Garner.configure do |config|
        config.mongoid_identity_fields = [:_id, :_slugs]
      end

      @monger = Monger.create({ :name => "M1" })
      @food = Food.create({ :name => "F1" })
    end

    it_behaves_like "Garner::Strategies::Binding::Key strategy" do
      let(:known_bindings) do
        [Activist.create, @monger, Monger.identify(@monger.id), Monger.identify("m1"), Monger]
      end
      let(:unknown_bindings) do
        [Monger.identify("m2"), Food.identify(nil), Monger.new, Activist.new]
      end
    end
  end
end
