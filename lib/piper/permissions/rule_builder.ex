defmodule Piper.Permissions.RuleBuilder do

  alias Piper.Permissions.Ast

  defstruct [:rule, :input_criteria, :perms_criteria]

  def new(command) when is_binary(command) do
    var = %Ast.Var{name: "command"}
    value = %Ast.String{value: command}
    command_selector = %Ast.BinaryExpr{op: :is, left: var, right: value}
    %__MODULE__{rule: %Ast.Rule{command_selector: command_selector}}
  end

  def add_input_criteria(%__MODULE__{input_criteria: nil}=builder, opts) do
    %{builder | input_criteria: build_binary_expr(opts)}
  end
  def add_input_criteria(%__MODULE__{input_criteria: ic}=builder, opts) do
    {boolean_op, opts} = determine_boolean_operator(opts)
    right = build_binary_expr(opts)
    %{builder | input_criteria: %Ast.ConditionalExpr{op: boolean_op, left: ic, right: right}}
  end

  def add_permission_criteria(%__MODULE__{perms_criteria: nil}=builder, opts) do
    pc = build_permission_expr(opts)
    %{builder | perms_criteria: pc}
  end
  def add_permission_criteria(%__MODULE__{perms_criteria: pc}=builder, opts) do
    {boolean_op, opts} = determine_boolean_operator(opts)
    right = build_permission_expr(opts)
    %{builder | perms_criteria: %Ast.ConditionalExpr{op: boolean_op, left: pc, right: right}}
  end

  def finish(%__MODULE__{rule: rule, input_criteria: nil, perms_criteria: pc}) do
    rule = %{rule | permission_selector: pc}
    "#{rule}"
  end
  def finish(%__MODULE__{rule: rule, input_criteria: ic, perms_criteria: pc}) do
    cs = %Ast.BinaryExpr{left: rule.command_selector, op: :with, right: ic}
    rule = %{rule | command_selector: cs, permission_selector: pc}
    "#{rule}"
  end

  defp build_permission_expr(opts) do
    case Keyword.get(opts, :all) do
      nil ->
        case Keyword.get(opts, :any) do
          nil ->
            case Keyword.get(opts, :permission) do
              nil ->
                raise "Missing permission criteria"
              value ->
                Ast.PermissionExpr.build(value)
            end
          value ->
            Ast.PermissionExpr.build(:any, value)
        end
      value ->
        Ast.PermissionExpr.build(:all, value)
    end
  end

  defp build_binary_expr(opts) do
    input = case determine_lhs_reference(opts, :arg, Ast.Arg) do
              nil ->
                case determine_lhs_reference(opts, :option, Ast.Option) do
                  nil ->
                    raise "lhs reference missing"
                  v ->
                    v
                end
              v ->
                v
            end
    op = determine_operator(opts)
    value = determine_rhs_value(opts)
    %Ast.BinaryExpr{left: input, right: value, op: op}
  end

  defp determine_lhs_reference(opts, key, type) do
    case Keyword.get(opts, key) do
      nil ->
        nil
      value ->
        type.build(value)
    end
  end

  defp determine_boolean_operator(opts) do
    case Keyword.get(opts, :and) do
      nil ->
        case Keyword.get(opts, :or) do
          nil ->
            raise "Expecting one of [\"and\", \"or\"] but found nil"
          expr when is_list(expr) ->
            if Keyword.keyword?(expr) do
              {:or, expr}
            else
              raise "Invalid sub expression: \"#{inspect expr}\""
            end
          expr ->
            raise "Invalid sub expression: \"#{inspect expr}\""
        end
      expr when is_list(expr) ->
        if Keyword.keyword?(expr) do
          {:and, expr}
        else
          raise "Invalid sub expression: \"#{inspect expr}\""
        end
      expr ->
        raise "Invalid sub expression: \"#{inspect expr}\""
    end
  end

  defp determine_operator(opts) do
    case Keyword.get(opts, :op) do
      nil ->
        raise "Missing comparison operator"
      op ->
        op
    end
  end

  defp determine_rhs_value(opts) do
    case Keyword.get(opts, :value) do
      nil ->
        raise "Missing rhs value"
      value when is_integer(value) ->
        %Ast.Integer{value: value}
      value when is_float(value) ->
        %Ast.Float{value: value}
      value when is_boolean(value) ->
        %Ast.Bool{value: value}
      value when is_binary(value) ->
        %Ast.String{value: value, quotes: "\""}
      %Regex{}=value ->
        %Ast.Regex{value: value}
      value ->
        raise "Type determination failed for value \"#{inspect value}\""
    end
  end
end
