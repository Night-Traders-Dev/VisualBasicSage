# VB4 Abstract Syntax Tree node definitions

class Node:
  proc init(self, node_type):
    self.type = node_type

class Module(Node):
  proc init(self):
    super.init("Module")
    self.declarations = []

class SubDecl(Node):
  proc init(self, name, params, body):
    super.init("SubDecl")
    self.name = name
    self.params = params
    self.body = body

class FunctionDecl(Node):
  proc init(self, name, params, return_type, body):
    super.init("FunctionDecl")
    self.name = name
    self.params = params
    self.return_type = return_type
    self.body = body

class PropertyGet(Node):
  proc init(self, name, params, return_type, body):
    super.init("PropertyGet")
    self.name = name
    self.params = params
    self.return_type = return_type
    self.body = body

class PropertyLet(Node):
  proc init(self, name, params, body):
    super.init("PropertyLet")
    self.name = name
    self.params = params
    self.body = body

class PropertySet(Node):
  proc init(self, name, params, body):
    super.init("PropertySet")
    self.name = name
    self.params = params
    self.body = body

class EventDecl(Node):
  proc init(self, name, params):
    super.init("EventDecl")
    self.name = name
    self.params = params

class TypeDecl(Node):
  proc init(self, name, fields):
    super.init("TypeDecl")
    self.name = name
    self.fields = fields

class EnumDecl(Node):
  proc init(self, name, members):
    super.init("EnumDecl")
    self.name = name
    self.members = members

class VariableDecl(Node):
  proc init(self, name, type_name):
    super.init("VariableDecl")
    self.name = name
    self.type_name = type_name

class ConstDecl(Node):
  proc init(self, name, type_name, value):
    super.init("ConstDecl")
    self.name = name
    self.type_name = type_name
    self.value = value

class Param(Node):
  proc init(self, name, type_name, by_ref):
    super.init("Param")
    self.name = name
    self.type_name = type_name
    self.by_ref = by_ref

class Block(Node):
  proc init(self, statements):
    super.init("Block")
    self.statements = statements

class Assignment(Node):
  proc init(self, target, value):
    super.init("Assignment")
    self.target = target
    self.value = value

class SetStatement(Node):
  proc init(self, target, value):
    super.init("SetStatement")
    self.target = target
    self.value = value

class CallStatement(Node):
  proc init(self, name, args):
    super.init("CallStatement")
    self.name = name
    self.args = args

class IfStatement(Node):
  proc init(self, condition, then_body, else_if_clauses, else_body):
    super.init("IfStatement")
    self.condition = condition
    self.then_body = then_body
    self.else_if_clauses = else_if_clauses
    self.else_body = else_body

class ElseIfClause(Node):
  proc init(self, condition, body):
    super.init("ElseIfClause")
    self.condition = condition
    self.body = body

class SelectCase(Node):
  proc init(self, expression, cases):
    super.init("SelectCase")
    self.expression = expression
    self.cases = cases

class CaseClause(Node):
  proc init(self, values, body):
    super.init("CaseClause")
    self.values = values
    self.body = body

class ForLoop(Node):
  proc init(self, variable, start, end, step, body):
    super.init("ForLoop")
    self.variable = variable
    self.start = start
    self.end = end
    self.step = step
    self.body = body

class ForEachLoop(Node):
  proc init(self, variable, collection, body):
    super.init("ForEachLoop")
    self.variable = variable
    self.collection = collection
    self.body = body

class DoLoop(Node):
  proc init(self, condition, loop_type, body):
    super.init("DoLoop")
    self.condition = condition
    self.loop_type = loop_type
    self.body = body

class WhileLoop(Node):
  proc init(self, condition, body):
    super.init("WhileLoop")
    self.condition = condition
    self.body = body

class WithBlock(Node):
  proc init(self, object, body):
    super.init("WithBlock")
    self.object = object
    self.body = body

class ExitStatement(Node):
  proc init(self, kind):
    super.init("ExitStatement")
    self.kind = kind

class GoToStatement(Node):
  proc init(self, label):
    super.init("GoToStatement")
    self.label = label

class OnError(Node):
  proc init(self, action, target):
    super.init("OnError")
    self.action = action
    self.target = target

class Resume(Node):
  proc init(self, target):
    super.init("Resume")
    self.target = target

class RaiseEvent(Node):
  proc init(self, name, args):
    super.init("RaiseEvent")
    self.name = name
    self.args = args

class RedimStatement(Node):
  proc init(self, name, dimensions, preserve):
    super.init("RedimStatement")
    self.name = name
    self.dimensions = dimensions
    self.preserve = preserve

class EraseStatement(Node):
  proc init(self, names):
    super.init("EraseStatement")
    self.names = names

class BinaryOp(Node):
  proc init(self, op, left, right):
    super.init("BinaryOp")
    self.op = op
    self.left = left
    self.right = right

class UnaryOp(Node):
  proc init(self, op, operand):
    super.init("UnaryOp")
    self.op = op
    self.operand = operand

class Literal(Node):
  proc init(self, literal_type, value):
    super.init("Literal")
    self.literal_type = literal_type
    self.value = value

class Identifier(Node):
  proc init(self, name):
    super.init("Identifier")
    self.name = name

class MemberAccess(Node):
  proc init(self, object, member):
    super.init("MemberAccess")
    self.object = object
    self.member = member

class ArrayAccess(Node):
  proc init(self, object, index):
    super.init("ArrayAccess")
    self.object = object
    self.index = index

class FunctionCall(Node):
  proc init(self, name, args):
    super.init("FunctionCall")
    self.name = name
    self.args = args

class NewExpr(Node):
  proc init(self, class_name):
    super.init("NewExpr")
    self.class_name = class_name

class NothingExpr(Node):
  proc init(self):
    super.init("NothingExpr")

class MeExpr(Node):
  proc init(self):
    super.init("MeExpr")
