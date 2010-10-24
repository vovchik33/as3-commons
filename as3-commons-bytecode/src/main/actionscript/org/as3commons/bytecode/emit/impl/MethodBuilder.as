/*
 * Copyright 2007-2010 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.as3commons.bytecode.emit.impl {
	import flash.errors.IllegalOperationError;

	import mx.utils.StringUtil;

	import org.as3commons.bytecode.abc.LNamespace;
	import org.as3commons.bytecode.abc.MethodInfo;
	import org.as3commons.bytecode.abc.MethodTrait;
	import org.as3commons.bytecode.abc.QualifiedName;
	import org.as3commons.bytecode.abc.TraitInfo;
	import org.as3commons.bytecode.abc.enum.BuiltIns;
	import org.as3commons.bytecode.abc.enum.TraitKind;
	import org.as3commons.bytecode.emit.IMethodBodyBuilder;
	import org.as3commons.bytecode.emit.IMethodBuilder;
	import org.as3commons.bytecode.emit.enum.MemberVisibility;
	import org.as3commons.bytecode.emit.util.BuildUtil;
	import org.as3commons.bytecode.typeinfo.Argument;
	import org.as3commons.bytecode.util.MultinameUtil;
	import org.as3commons.lang.Assert;
	import org.as3commons.lang.StringUtils;

	public class MethodBuilder extends EmitMember implements IMethodBuilder {

		private static const MULTIPLE_METHOD_BODIES_ERROR:String = "Only one method body can be created for a method.";
		private static const CONSTANT_METHOD_ERROR:String = "Methods cannot be constant.";

		private var _returnType:String = BuiltIns.VOID.fullName;
		private var _arguments:Array = [];
		private var _methodBodyBuilder:IMethodBodyBuilder;
		private var _hasRestArguments:Boolean;

		public function MethodBuilder(name:String = null, visibility:MemberVisibility = null, nameSpace:String = null) {
			super(name, visibility, nameSpace);
		}

		public function get arguments():Array {
			return _arguments;
		}

		public function set arguments(value:Array):void {
			_arguments = value;
		}

		public function get returnType():String {
			return _returnType;
		}

		public function set returnType(value:String):void {
			_returnType = value;
		}

		public function get hasRestArguments():Boolean {
			return _hasRestArguments;
		}

		public function set hasRestArguments(value:Boolean):void {
			_hasRestArguments = value;
		}

		override public function get isConstant():Boolean {
			return false;
		}

		override public function set isConstant(value:Boolean):void {
			throw new IllegalOperationError(CONSTANT_METHOD_ERROR);
		}

		public function defineMethodBody():IMethodBodyBuilder {
			if (_methodBodyBuilder != null) {
				throw new IllegalOperationError(MULTIPLE_METHOD_BODIES_ERROR);
			}
			_methodBodyBuilder = new MethodBodyBuilder();
			return _methodBodyBuilder;
		}

		public function defineArgument(type:String = "", isOptional:Boolean = false, defaultValue:Object = null):MethodArgument {
			var arg:MethodArgument = new MethodArgument();
			arg.type = type;
			arg.isOptional = isOptional;
			arg.defaultValue = defaultValue;
			_arguments[_arguments.length] = arg;
			return arg;
		}

		public function build(initScopeDepth:uint = 1):Array {
			var mi:MethodInfo = new MethodInfo();
			if (_methodBodyBuilder != null) {
				mi.methodBody = _methodBodyBuilder.build(initScopeDepth);
				mi.methodBody.methodSignature = mi;
				mi.methodBody.localCount = 1 + mi.argumentCollection.length + ((_hasRestArguments) ? 1 : 0);
			}
			for each (var methodArg:MethodArgument in _arguments) {
				var arg:Argument = new Argument(MultinameUtil.toQualifiedName(methodArg.type), methodArg.isOptional, methodArg.defaultValue, BuildUtil.toConstantKind(methodArg.defaultValue));
				mi.argumentCollection[mi.argumentCollection.length] = arg;
			}
			trait = buildTrait();
			MethodTrait(trait).traitMethod = mi;
			trait.addMetadataList(buildMetadata());
			mi.as3commonsByteCodeAssignedMethodTrait = MethodTrait(trait);
			mi.returnType = MultinameUtil.toQualifiedName(_returnType);
			mi.methodName = StringUtils.substitute(ClassBuilder.METHOD_NAME, packageName, name);
			return [mi, trait.metadata];
		}

		override protected function buildTrait():TraitInfo {
			Assert.hasText(name, "name property must not be null or empty");
			Assert.hasText(packageName, "packageName property must not be null or empty");
			Assert.notNull(visibility, "visibility property must not be null");
			Assert.notNull(VISIBILITY_LOOKUP[visibility], "visibility lookup must not be null");
			var trait:MethodTrait = new MethodTrait();
			trait.traitKind = TraitKind.METHOD;
			trait.isFinal = isFinal;
			trait.isOverride = isOverride;
			var ns:LNamespace = new LNamespace(NAMESPACEKIND_LOOKUP[visibility], "");
			trait.traitMultiname = new QualifiedName(name, ns);
			return trait;
		}

	}
}