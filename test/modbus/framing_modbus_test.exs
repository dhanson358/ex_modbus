defmodule FramingModbusTest do
  use ExUnit.Case
  alias ExModbus.Nerves.UART.Framing.Modbus

  test "adds framing (does nothing)" do
    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)
    assert {:ok, "", ^line} = Modbus.add_framing("", line)
    assert {:ok, "ABC\n", ^line} = Modbus.add_framing("ABC\n", line)
  end

  test "handles broken up lines" do
    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)

    assert {:in_frame, [], line} = Modbus.remove_framing(<<1, 3, 4, 0, 13>>, line)
    assert {:ok, [<<1, 3, 4, 0, 13, 0, 54, 235, 230>>], line} = Modbus.remove_framing(<<0, 54, 235, 230>>, line)

    assert Modbus.buffer_empty?(line) == true
  end

  test "handles everything in one line" do
    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)

    assert {:ok, [<<1, 3, 4, 0, 13, 0, 54, 235, 230>>], line} = Modbus.remove_framing(<<1, 3, 4, 0, 13, 0, 54, 235, 230>>, line)
    assert Modbus.buffer_empty?(line) == true
  end

  test "rejects invalid CRC" do
    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)

    assert {:error, :invalid_crc, line} = Modbus.remove_framing(<<1, 3, 4, 0, 13, 0, 54, 235, 25>>, line)
    assert Modbus.buffer_empty?(line) == true
  end

  test "deals with extra junk data across multiple frames" do
    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)

    assert {:in_frame, [], line} = Modbus.remove_framing(<<1, 3, 4, 0, 13>>, line)
    assert {:ok, [<<1, 3, 4, 0, 13, 0, 54, 235, 230>>], line} = Modbus.remove_framing(<<0, 54, 235, 230, 5, 5, 5>>, line)
    assert Modbus.buffer_empty?(line) == true
  end

  test "deals with extra junk data in one frame" do
    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)
    assert {:ok, [<<1, 3, 4, 0, 13, 0, 54, 235, 230>>], line} = Modbus.remove_framing(<<1, 3, 4, 0, 13, 0, 54, 235, 230, 5, 5, 5, 5>>, line)
    assert Modbus.buffer_empty?(line) == true
  end

  test "handles response from write" do
    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)

    assert {:ok, [<<1, 16, 16, 4, 0, 2, 4, 201>>], line} = Modbus.remove_framing(<<1, 16, 16, 4, 0, 2, 4, 201>>, line)
    assert Modbus.buffer_empty?(line) == true
  end

  test "handles first packet being a single byte only (func 3)" do

    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)

    assert {:in_frame, [], line} = Modbus.remove_framing(<<1>>, line)
    assert {:in_frame, [], line} = Modbus.remove_framing(<<3, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, line)
    assert {:in_frame, [], line} = Modbus.remove_framing(<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, line)
    assert {:in_frame, [], line} = Modbus.remove_framing(<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 23, 0, 25, 0>>, line)

    assert {:ok, [
      <<1, 3, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 23, 0, 25, 0, 48, 0, 10, 0, 5, 0, 16, 186, 1>>
      ], _line} = Modbus.remove_framing(<<48, 0, 10, 0, 5, 0, 16, 186, 1>>, line)

  end

  test "handles first two packets being a single byte only (func 3)" do

    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)

    assert {:in_frame, [], line} = Modbus.remove_framing(<<1>>, line)
    assert {:in_frame, [], line} = Modbus.remove_framing(<<3>>, line)
    assert {:in_frame, [], line} = Modbus.remove_framing(<<50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, line)
    assert {:in_frame, [], line} = Modbus.remove_framing(<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, line)
    assert {:in_frame, [], line} = Modbus.remove_framing(<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 23, 0, 25, 0>>, line)

    assert {:ok, [
      <<1, 3, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 23, 0, 25, 0, 48, 0, 10, 0, 5, 0, 16, 186, 1>>
      ], _line} = Modbus.remove_framing(<<48, 0, 10, 0, 5, 0, 16, 186, 1>>, line)

  end

  test "handles first packet being a single byte only (func 16)" do

    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)

    assert {:in_frame, [], line} = Modbus.remove_framing(<<1>>, line)
    assert {:in_frame, [], line} = Modbus.remove_framing(<<16, 0, 1>>, line)

    assert {:ok, [
      <<0x01, 0x10, 0x00, 0x01, 0x00, 0x02, 16, 8>>
      ], _line} = Modbus.remove_framing(<<0, 2, 16, 8>>, line)

  end

  test "handles empty responses in middle of stream" do

    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)

    assert {:in_frame, [], line} = Modbus.remove_framing(<<1>>, line)
    assert {:in_frame, [], line} = Modbus.remove_framing(<<>>, line)
    assert {:in_frame, [], line} = Modbus.remove_framing(<<16, 0, 1>>, line)

    assert {:ok, [
      <<0x01, 0x10, 0x00, 0x01, 0x00, 0x02, 16, 8>>
      ], _line} = Modbus.remove_framing(<<0, 2, 16, 8>>, line)

  end

  test "handles short resp" do

    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)

    assert {:in_frame, [], line} = Modbus.remove_framing(<<1, 3, 8, 0>>, line)
    assert {:in_frame, [], line} = Modbus.remove_framing(<<0, 0, 0, 0, 0, 0, 0>>, line)

    assert {:ok, [
      <<1, 3, 8, 0, 0, 0, 0, 0, 0, 0, 0, 149, 215>>
      ], _line} = Modbus.remove_framing(<<149, 215>>, line)


  end


    test "handles code func 3 error" do

      {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)

      assert {:error, :modbus_exception, _line} = Modbus.remove_framing(<<1, 131, 02, 192, 241>>, line)

    end

    test "handles code func 16 error" do

      {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)

      assert {:error, :modbus_exception, _line} = Modbus.remove_framing(<<1, 144, 03, 12, 1>>, line)

    end

  test "handle write single coil response" do
    resp = <<0x01, 0x05, 0x05, 0xDD, 0xFF, 0x00, 0x1C, 0xCC>>
    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)
    assert {:ok, [<<0x01, 0x05, 0x05, 0xDD, 0xFF, 0x00, 0x1C, 0xCC>>], _line} = Modbus.remove_framing(resp, line)
  end

  test "handles write single coil response plus extra data" do
    resp = <<0x01, 0x05, 0x05, 0xDD, 0xFF, 0x00, 0x1C, 0xCC, 0xFB, 0x04, 0x00, 0x00, 0x00, 0x04, 0xE5, 0x93>>
    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)
    assert {:ok, [<<0x01, 0x05, 0x05, 0xDD, 0xFF, 0x00, 0x1C, 0xCC>>], _line} = Modbus.remove_framing(resp, line)
  end
end
