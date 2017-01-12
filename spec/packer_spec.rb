# encoding: ascii-8bit
require 'spec_helper'

require 'stringio'
if defined?(Encoding)
  Encoding.default_external = 'ASCII-8BIT'
end

describe Packer do
  let :packer do
    Packer.new
  end

  it 'initialize' do
    Packer.new
    Packer.new(nil)
    Packer.new(StringIO.new)
    Packer.new({})
    Packer.new(StringIO.new, {})
  end

  #it 'Packer' do
  #  Packer(packer).object_id.should == packer.object_id
  #  Packer(nil).class.should == Packer
  #  Packer('').class.should == Packer
  #  Packer('initbuf').to_s.should == 'initbuf'
  #end

  it 'write' do
    packer.write([])
    packer.to_s.should == "\x90"
  end

  it 'write_nil' do
    packer.write_nil
    packer.to_s.should == "\xc0"
  end

  it 'write_array_header 0' do
    packer.write_array_header(0)
    packer.to_s.should == "\x90"
  end

  it 'write_array_header 1' do
    packer.write_array_header(1)
    packer.to_s.should == "\x91"
  end

  it 'write_map_header 0' do
    packer.write_map_header(0)
    packer.to_s.should == "\x80"
  end

  it 'write_map_header 1' do
    packer.write_map_header(1)
    packer.to_s.should == "\x81"
  end

  it 'flush' do
    io = StringIO.new
    pk = Packer.new(io)
    pk.write_nil
    pk.flush
    pk.to_s.should == ''
    io.string.should == "\xc0"
  end

  it 'buffer' do
    o1 = packer.buffer.object_id
    packer.buffer << 'frsyuki'
    packer.buffer.to_s.should == 'frsyuki'
    packer.buffer.object_id.should == o1
  end

  it 'to_msgpack returns String' do
    nil.to_msgpack.class.should == String
    true.to_msgpack.class.should == String
    false.to_msgpack.class.should == String
    1.to_msgpack.class.should == String
    1.0.to_msgpack.class.should == String
    "".to_msgpack.class.should == String
    Hash.new.to_msgpack.class.should == String
    Array.new.to_msgpack.class.should == String
  end

  class CustomPack01
    def to_msgpack(pk=nil)
      return MessagePack.pack(self, pk) unless pk.class == MessagePack::Packer
      pk.write_array_header(2)
      pk.write(1)
      pk.write(2)
      return pk
    end
  end

  class CustomPack02
    def to_msgpack(pk=nil)
      [1,2].to_msgpack(pk)
    end
  end

  it 'calls custom to_msgpack method' do
    MessagePack.pack(CustomPack01.new).should == [1,2].to_msgpack
    MessagePack.pack(CustomPack02.new).should == [1,2].to_msgpack
    CustomPack01.new.to_msgpack.should == [1,2].to_msgpack
    CustomPack02.new.to_msgpack.should == [1,2].to_msgpack
  end

  it 'calls custom to_msgpack method with io' do
    s01 = StringIO.new
    MessagePack.pack(CustomPack01.new, s01)
    s01.string.should == [1,2].to_msgpack

    s02 = StringIO.new
    MessagePack.pack(CustomPack02.new, s02)
    s02.string.should == [1,2].to_msgpack

    s03 = StringIO.new
    CustomPack01.new.to_msgpack(s03)
    s03.string.should == [1,2].to_msgpack

    s04 = StringIO.new
    CustomPack02.new.to_msgpack(s04)
    s04.string.should == [1,2].to_msgpack
  end

  #context 'in compatibility mode' do
  #  it 'does not use the bin types' do
  #    packed = MessagePack.pack('hello'.force_encoding(Encoding::BINARY), compatibility_mode: true)
  #    packed.should eq("\xA5hello")
  #    packed = MessagePack.pack(('hello' * 100).force_encoding(Encoding::BINARY), compatibility_mode: true)
  #    packed.should start_with("\xDA\x01\xF4")

  #    packer = MessagePack::Packer.new(compatibility_mode: 1)
  #    packed = packer.pack(('hello' * 100).force_encoding(Encoding::BINARY))
  #    packed.to_str.should start_with("\xDA\x01\xF4")
  #  end

  #  it 'does not use the str8 type' do
  #    packed = MessagePack.pack('x' * 32, compatibility_mode: true)
  #    packed.should start_with("\xDA\x00\x20")
  #  end
  #end

  #class ValueOne
  #  def initialize(num)
  #    @num = num
  #  end
  #  def num
  #    @num
  #  end
  #  def to_msgpack_ext
  #    @num.to_msgpack
  #  end
  #  def self.from_msgpack_ext(data)
  #    self.new(MessagePack.unpack(data))
  #  end
  #end

  #class ValueTwo
  #  def initialize(num)
  #    @num_s = num.to_s
  #  end
  #  def num
  #    @num_s.to_i
  #  end
  #  def to_msgpack_ext
  #    @num_s.to_msgpack
  #  end
  #  def self.from_msgpack_ext(data)
  #    self.new(MessagePack.unpack(data))
  #  end
  #end

  #describe '#type_registered?' do
  #  it 'receive Class or Integer, and return bool' do
  #    expect(subject.type_registered?(0x00)).to be_falsy
  #    expect(subject.type_registered?(0x01)).to be_falsy
  #    expect(subject.type_registered?(::ValueOne)).to be_falsy
  #  end

  #  it 'returns true if specified type or class is already registered' do
  #    subject.register_type(0x30, ::ValueOne, :to_msgpack_ext)
  #    subject.register_type(0x31, ::ValueTwo, :to_msgpack_ext)

  #    expect(subject.type_registered?(0x00)).to be_falsy
  #    expect(subject.type_registered?(0x01)).to be_falsy

  #    expect(subject.type_registered?(0x30)).to be_truthy
  #    expect(subject.type_registered?(0x31)).to be_truthy
  #    expect(subject.type_registered?(::ValueOne)).to be_truthy
  #    expect(subject.type_registered?(::ValueTwo)).to be_truthy
  #  end
  #end

  #describe '#register_type' do
  #  it 'get type and class mapping for packing' do
  #    packer = MessagePack::Packer.new
  #    packer.register_type(0x01, ValueOne){|obj| obj.to_msgpack_ext }
  #    packer.register_type(0x02, ValueTwo){|obj| obj.to_msgpack_ext }

  #    packer = MessagePack::Packer.new
  #    packer.register_type(0x01, ValueOne, :to_msgpack_ext)
  #    packer.register_type(0x02, ValueTwo, :to_msgpack_ext)

  #    packer = MessagePack::Packer.new
  #    packer.register_type(0x01, ValueOne, &:to_msgpack_ext)
  #    packer.register_type(0x02, ValueTwo, &:to_msgpack_ext)
  #  end

  #  it 'returns a Hash which contains map of Class and type' do
  #    packer = MessagePack::Packer.new
  #    packer.register_type(0x01, ValueOne, :to_msgpack_ext)
  #    packer.register_type(0x02, ValueTwo, :to_msgpack_ext)

  #    expect(packer.registered_types).to be_a(Array)
  #    expect(packer.registered_types.size).to eq(2)

  #    one = packer.registered_types[0]
  #    expect(one.keys.sort).to eq([:type, :class, :packer].sort)
  #    expect(one[:type]).to eq(0x01)
  #    expect(one[:class]).to eq(ValueOne)
  #    expect(one[:packer]).to eq(:to_msgpack_ext)

  #    two = packer.registered_types[1]
  #    expect(two.keys.sort).to eq([:type, :class, :packer].sort)
  #    expect(two[:type]).to eq(0x02)
  #    expect(two[:class]).to eq(ValueTwo)
  #    expect(two[:packer]).to eq(:to_msgpack_ext)
  #  end
  #end

  describe "fixnum and bignum" do
    it "fixnum.to_msgpack" do
      23.to_msgpack.should == "\x17"
    end

    it "fixnum.to_msgpack(packer)" do
      23.to_msgpack(packer)
      packer.to_s.should == "\x17"
    end

    it "bignum.to_msgpack" do
      -4294967296.to_msgpack.should == "\xD3\xFF\xFF\xFF\xFF\x00\x00\x00\x00"
    end

    it "bignum.to_msgpack(packer)" do
      -4294967296.to_msgpack(packer)
      packer.to_s.should == "\xD3\xFF\xFF\xFF\xFF\x00\x00\x00\x00"
    end

    it "unpack(fixnum)" do
      MessagePack.unpack("\x17").should == 23
    end

    it "unpack(bignum)" do
      MessagePack.unpack("\xD3\xFF\xFF\xFF\xFF\x00\x00\x00\x00").should == -4294967296
    end
  end

  #describe "ext formats" do
  #  [1, 2, 4, 8, 16].zip([0xd4, 0xd5, 0xd6, 0xd7, 0xd8]).each do |n,b|
  #    it "msgpack fixext #{n} format" do
  #      MessagePack::ExtensionValue.new(1, "a"*n).to_msgpack.should ==
  #        [b, 1].pack('CC') + "a"*n
  #    end
  #  end

  #  it "msgpack ext 8 format" do
  #    MessagePack::ExtensionValue.new(1, "").to_msgpack.should ==
  #      [0xc7, 0, 1].pack('CCC') + ""
  #    MessagePack::ExtensionValue.new(-1, "a"*255).to_msgpack.should ==
  #      [0xc7, 255, -1].pack('CCC') + "a"*255
  #  end

  #  it "msgpack ext 16 format" do
  #    MessagePack::ExtensionValue.new(1, "a"*256).to_msgpack.should ==
  #      [0xc8, 256, 1].pack('CnC') + "a"*256
  #    MessagePack::ExtensionValue.new(-1, "a"*65535).to_msgpack.should ==
  #      [0xc8, 65535, -1].pack('CnC') + "a"*65535
  #  end

  #  it "msgpack ext 32 format" do
  #    MessagePack::ExtensionValue.new(1, "a"*65536).to_msgpack.should ==
  #      [0xc9, 65536, 1].pack('CNC') + "a"*65536
  #    MessagePack::ExtensionValue.new(-1, "a"*65538).to_msgpack.should ==
  #      [0xc9, 65538, -1].pack('CNC') + "a"*65538
  #  end
  #end
end

