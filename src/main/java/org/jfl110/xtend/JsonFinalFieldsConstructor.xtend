package org.jfl110.xtend

import com.google.common.annotations.Beta
import com.google.common.annotations.GwtCompatible
import java.lang.annotation.ElementType
import java.lang.annotation.Target
import java.util.List
import java.util.regex.Pattern
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.TransformationParticipant
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableConstructorDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableTypeParameterDeclarator
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import java.lang.annotation.Documented
import org.eclipse.xtend.lib.annotations.Accessors
import com.fasterxml.jackson.annotation.JsonCreator
import com.fasterxml.jackson.annotation.JsonProperty
import com.google.common.collect.ImmutableList
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.MutableParameterDeclaration
import org.eclipse.xtend.lib.annotations.Data
import com.google.common.collect.ImmutableSet
import java.util.Set
import com.google.common.collect.ImmutableMap
import java.util.Map

/**
 * Modified copy of {@link org.eclipse.xtend.lib.annotations.FinalFieldsConstructor}
 */
@Target(#[ElementType.TYPE, ElementType.CONSTRUCTOR])
@GwtCompatible
@Beta
@Active(FinalFieldsConstructorProcessor)
@Documented
annotation FinalFieldsConstructor {
}

/**
 * Modified copy of {@link org.eclipse.xtend.lib.annotations.FinalFieldsConstructorProcessor}
 */
@Beta
class FinalFieldsConstructorProcessor implements TransformationParticipant<MutableTypeParameterDeclarator> {

	override doTransform(List<? extends MutableTypeParameterDeclarator> elements,
		extension TransformationContext context) {
		elements.forEach[transform(context)]
	}

	def dispatch void transform(MutableClassDeclaration it, extension TransformationContext context) {
		if (findAnnotation(Data.findTypeGlobally) !== null) {
			return
		}
		if (findAnnotation(Accessors.findTypeGlobally) !== null) {
			return
		}
		val extension util = new FinalFieldsConstructorProcessor.Util(context)
		addFinalFieldsConstructor
	}

	def dispatch void transform(MutableConstructorDeclaration it, extension TransformationContext context) {
		val extension util = new FinalFieldsConstructorProcessor.Util(context)
		makeFinalFieldsConstructor
	}

	/**
	 * @since 2.7
	 * @noextend
	 * @noreference
	 */
	@Beta
	static class Util {
		extension TransformationContext context
		final JsonDataFieldNameHelper fieldNameExtractor = new JsonDataFieldNameHelper();
		final Type immutList;
		final Type immutSet;
		final Type immutMap;

		new(TransformationContext context) {
			this.context = context
			this.immutList = context.findTypeGlobally(ImmutableList);
			this.immutSet = context.findTypeGlobally(ImmutableSet);
			this.immutMap = context.findTypeGlobally(ImmutableMap);

		}

		def getFinalFields(MutableTypeDeclaration it) {
			declaredFields.filter[!static && final == true && initializer === null && thePrimaryGeneratedJavaElement]
		}

		def needsFinalFieldConstructor(MutableClassDeclaration it) {
			!hasFinalFieldsConstructor && (primarySourceElement as ClassDeclaration).declaredConstructors.isEmpty
		}

		def hasFinalFieldsConstructor(MutableTypeDeclaration cls) {
			val expectedTypes = cls.finalFieldsConstructorArgumentTypes
			cls.declaredConstructors.exists [
				parameters.map[type].toList == expectedTypes
			]
		}

		def getFinalFieldsConstructorArgumentTypes(MutableTypeDeclaration cls) {
			val types = newArrayList
			if (cls.superConstructor !== null) {
				types += cls.superConstructor.resolvedParameters.map[resolvedType]
			}
			types += cls.finalFields.map[type]
			types
		}

		def String getConstructorAlreadyExistsMessage(MutableTypeDeclaration it) {
			'''Cannot create FinalFieldsConstructor as a constructor with the signature "new(«finalFieldsConstructorArgumentTypes.join(",")»)" already exists.'''
		}

		def addFinalFieldsConstructor(MutableClassDeclaration it) {
			if (finalFieldsConstructorArgumentTypes.empty) {
				val anno = findAnnotation(FinalFieldsConstructor.findTypeGlobally)
				anno.addWarning('''There are no final fields, this annotation has no effect''')
				return
			}
			if (hasFinalFieldsConstructor) {
				addError(constructorAlreadyExistsMessage)
				return
			}
			addConstructor [
				primarySourceElement = declaringType.primarySourceElement
				makeFinalFieldsConstructor
			]
		}

		static val EMPTY_BODY = Pattern.compile("(\\{(\\s*\\})?)?")

		def makeFinalFieldsConstructor(MutableConstructorDeclaration it) {
			if (declaringType.finalFieldsConstructorArgumentTypes.empty) {
				val anno = findAnnotation(FinalFieldsConstructor.findTypeGlobally)
				anno.addWarning('''There are no final fields, this annotation has no effect''')
				return
			}
			if (declaringType.hasFinalFieldsConstructor) {
				addError(declaringType.constructorAlreadyExistsMessage)
				return
			}
			if (!parameters.empty) {
				addError("Parameter list must be empty")
			}
			if (body !== null && !EMPTY_BODY.matcher(body.toString).matches) {
				addError("Body must be empty")
			}
			val superParameters = declaringType.superConstructor?.resolvedParameters ?: #[]
			superParameters.forEach [ p |
				addParameter(p.declaration.simpleName, p.resolvedType)
			]
			val fieldToParameter = newHashMap
			val bodyAssign = new StringBuilder()
			declaringType.finalFields.forEach [ p |
				p.markAsInitializedBy(it)

				var MutableParameterDeclaration param = null;

				// ImmutableList handling
				if (immutList.toString() == p.type.orObject.type.toString()) {
					param = addParameter(p.simpleName,
						context.newTypeReference(List, p.type.orObject.actualTypeArguments))
					bodyAssign.append(
						"this." + p.simpleName + " = " + param.simpleName +
							" == null ? ImmutableList.of() : ImmutableList.copyOf(" + param.simpleName + ");\n");

				} else // ImmutableSet handling
				if (immutSet.toString() == p.type.orObject.type.toString()) {
					param = addParameter(p.simpleName,
						context.newTypeReference(Set, p.type.orObject.actualTypeArguments))
					bodyAssign.append(
						"this." + p.simpleName + " = " + param.simpleName +
							" == null ? ImmutableSet.of() : ImmutableSet.copyOf(" + param.simpleName + ");\n");
				} else // ImmutableMap handling
				if (immutMap.toString() == p.type.orObject.type.toString()) {
					param = addParameter(p.simpleName,
						context.newTypeReference(Map, p.type.orObject.actualTypeArguments))
					bodyAssign.append(
						"this." + p.simpleName + " = " + param.simpleName +
							" == null ? ImmutableMap.of() : ImmutableMap.copyOf(" + param.simpleName + ");\n");
				} else {
					param = addParameter(p.simpleName, p.type.orObject)
					bodyAssign.append("this." + p.simpleName + " = " + param.simpleName + ";\n");
				}

				fieldToParameter.put(p, param)

				param.addAnnotation(
					this.context.newAnnotationReference(
						JsonProperty,
						[ a |
							a.set("value", fieldNameExtractor.jsonParamName(p, this.context))
						]
					)
				)
			]

			// Json creator annotation
			addAnnotation(this.context.newAnnotationReference(JsonCreator));

			body = '''
				super(«superParameters.join(", ")[declaration.simpleName]»);
				«bodyAssign»
			'''
		}

		def getSuperConstructor(TypeDeclaration it) {
			if (it instanceof ClassDeclaration) {
				if (extendedClass == object || extendedClass === null)
					return null;
				return extendedClass.declaredResolvedConstructors.head
			} else {
				return null
			}
		}

		private def orObject(TypeReference ref) {
			if(ref === null) object else ref
		}
	}
}
