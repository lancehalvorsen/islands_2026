defmodule IslandsEngine.RulesTest do
  use ExUnit.Case, async: true

  alias IslandsEngine.Rules

  describe "new/0" do
    test "returns a new Rules struct" do
      rules = Rules.new()
      assert rules.state == :initialized
      assert rules.player1 == :islands_not_set
      assert rules.player2 == :islands_not_set
    end
  end

  describe "check/2" do
    setup do
      rules = Rules.new()
      %{rules: rules}
    end

    test "with an invalid state", %{rules: rules} do
      rules = %{rules | state: :wildly_wrong_state}

      assert :error == Rules.check(rules, :add_player)
    end

    test "with an invalid action", %{rules: rules} do
      assert :error == Rules.check(rules, :totally_incorrect_action)
    end

    test "when state is :initialized and action is :add_player", %{rules: rules} do
      {:ok, rules} = Rules.check(rules, :add_player)
      assert rules.state == :players_set
    end

    test "when state is :initialized and action is not :add_player", %{rules: rules} do
      assert :error == Rules.check(rules, {:position_islands, :player1})
      assert :error == Rules.check(rules, {:position_islands, :player2})

      assert :error == Rules.check(rules, {:set_islands, :player1})
      assert :error == Rules.check(rules, {:set_islands, :player2})

      assert :error == Rules.check(rules, {:guess_coordinate, :player1})
      assert :error == Rules.check(rules, {:guess_coordinate, :player2})

      assert :error == Rules.check(rules, {:win_check, :win})
      assert :error == Rules.check(rules, {:win_check, :no_win})
    end

    test "when the state is :players_set and the action is :position_islands", %{rules: rules} do
      rules = %{rules | state: :players_set}

      assert {:ok, rules} = Rules.check(rules, {:position_islands, :player1})
      assert rules.state == :players_set
      assert rules.player1 == :islands_not_set
      assert rules.player2 == :islands_not_set

      assert {:ok, rules} = Rules.check(rules, {:position_islands, :player2})
      assert rules.state == :players_set
      assert rules.player1 == :islands_not_set
      assert rules.player2 == :islands_not_set
    end

    test "when the state is :players_set and the action is :set_islands", %{rules: rules} do
      rules = %{rules | state: :players_set}

      assert {:ok, rules} = Rules.check(rules, {:set_islands, :player1})
      assert rules.state == :players_set
      assert rules.player1 == :islands_set
      assert rules.player2 == :islands_not_set

      assert {:ok, rules} = Rules.check(rules, {:set_islands, :player2})
      assert rules.state == :player1_turn
      assert rules.player1 == :islands_set
      assert rules.player2 == :islands_set
    end

    test "when the state is :players_set and the action is neither :position_islands nor :set_islands",
         %{rules: rules} do
      rules = %{rules | state: :players_set}

      assert :error == Rules.check(rules, :add_player)

      assert :error == Rules.check(rules, {:guess_coordinate, :player1})
      assert :error == Rules.check(rules, {:guess_coordinate, :player2})

      assert :error == Rules.check(rules, {:win_check, :win})
      assert :error == Rules.check(rules, {:win_check, :no_win})
    end

    test "when the state is :player1_turn and action is :guess_coordinate", %{rules: rules} do
      rules = %{rules | state: :player1_turn}

      assert :error == Rules.check(rules, {:guess_coordinate, :player2})
      assert {:ok, rules} = Rules.check(rules, {:guess_coordinate, :player1})

      assert rules.state == :player2_turn
    end

    test "when the state is :player1_turn and action is :win_check", %{rules: rules} do
      rules = %{rules | state: :player1_turn}

      assert {:ok, rules} = Rules.check(rules, {:win_check, :no_win})
      assert rules.state == :player1_turn

      assert {:ok, rules} = Rules.check(rules, {:win_check, :win})
      assert rules.state == :game_over
    end

    test "when the status is :player1_turn and the action is neither :guess_coordinate nor :win_check",
         %{rules: rules} do
      rules = %{rules | state: :player1_turn}

      assert :error == Rules.check(rules, :add_player)

      assert :error == Rules.check(rules, {:position_islands, :player1})
      assert :error == Rules.check(rules, {:position_islands, :player2})

      assert :error == Rules.check(rules, {:set_islands, :player1})
      assert :error == Rules.check(rules, {:set_islands, :player2})
    end

    test "when the state is :player2_turn and action is :guess_coordinate", %{rules: rules} do
      rules = %{rules | state: :player2_turn}

      assert :error == Rules.check(rules, {:guess_coordinate, :player1})
      assert {:ok, rules} = Rules.check(rules, {:guess_coordinate, :player2})

      assert rules.state == :player1_turn
    end

    test "when the state is :player2_turn and action is :win_check", %{rules: rules} do
      rules = %{rules | state: :player2_turn}

      assert {:ok, rules} = Rules.check(rules, {:win_check, :no_win})
      assert rules.state == :player2_turn

      assert {:ok, rules} = Rules.check(rules, {:win_check, :win})
      assert rules.state == :game_over
    end

    test "when the status is :player2_turn and the action is neither :guess_coordinate nor :win_check",
         %{rules: rules} do
      rules = %{rules | state: :player2_turn}

      assert :error == Rules.check(rules, :add_player)

      assert :error == Rules.check(rules, {:position_islands, :player1})
      assert :error == Rules.check(rules, {:position_islands, :player2})

      assert :error == Rules.check(rules, {:set_islands, :player1})
      assert :error == Rules.check(rules, {:set_islands, :player2})
    end
  end
end
