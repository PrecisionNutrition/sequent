require 'spec_helper'

class Person < Sequent::Core::ValueObject
  attrs name: String
end

class House < Sequent::Core::ValueObject
  attrs owner: Person
end

describe Sequent::Core::Helpers::ParamSupport do
  let(:ben) { Person.new(name: "Ben Vonk") }
  it "can translate an object from and into params" do
    expect(Person.from_params(ben.as_params)).to eq(ben)
  end

  it "can translate nested objects from and into params" do
    house = House.new(person: ben)
    expect(House.from_params(house.as_params)).to eq(house)
  end

  context DateTime do
    class ParamWithDateTime < Sequent::Core::ValueObject
      attrs value: DateTime
    end

    it "handles datetime" do
      obj = ParamWithDateTime.new(value: DateTime.now.iso8601)
      expect(ParamWithDateTime.from_params(obj.as_params)).to eq(obj)
    end
  end

  context Sequent::Core::Helpers::ArrayWithType do
    class ParamWithArray < Sequent::Core::ValueObject
      attrs values: array(Integer)
    end

    class ParamWithValueObjectArray < Sequent::Core::ValueObject
      attrs values: array(Person)
    end

    class ParamWithNestedArrays < Sequent::Core::ValueObject
      attrs values: array(ParamWithArray)
    end

    context ParamWithArray do
      it "does not include empty arrays" do
        subject = ParamWithArray.new(values: [])
        expect(subject.to_params(:param_with_array)).to eq ({})
      end

      it "creates correct params" do
        subject = ParamWithArray.new(values: [1, 2])
        expect(subject.to_params(:param_with_array)).to eq ({"param_with_array[values][]" => [1, 2]})
      end

      it "creates an invalid object from invalid params" do
        params = {'values' => 'string'}
        expect(ParamWithArray.from_params(params)).to_not be_valid
      end
    end

    context ParamWithValueObjectArray do
      it "creates correct params" do
        subject = ParamWithValueObjectArray.new(values: [Person.new(name: "Ben"), Person.new(name: "Kim")])
        expect(subject.to_params(:foo)).to eq ({"foo[values][][name]" => ["Ben", "Kim"]})
      end

    end

    context ParamWithNestedArrays do
      let(:subject) { subject = ParamWithNestedArrays.new(values: [ParamWithArray.new(values: [1, 2])]) }
      it "creates correct params" do
        expect(subject.to_params(:foo)).to eq ({"foo[values][][values][]" => [1, 2]})
      end

      it "can recreate from params" do
        expect(ParamWithNestedArrays.from_params(subject.as_params)).to eq subject
      end
    end
  end

end
