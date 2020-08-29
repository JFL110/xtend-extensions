package org.jfl110.xtend

import com.google.common.annotations.Beta
import com.google.common.annotations.GwtCompatible
import java.lang.annotation.ElementType
import java.lang.annotation.Target
import java.util.List
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.TransformationParticipant
import org.eclipse.xtend.lib.macro.declaration.AnnotationTarget
import org.eclipse.xtend.lib.macro.declaration.FieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableFieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableMemberDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.declaration.Visibility
import java.lang.annotation.Documented
import com.fasterxml.jackson.annotation.JsonProperty
import org.eclipse.xtend.lib.annotations.Data
import org.jfl110.xtend.FinalFieldsConstructor

/**
 * Modified copy of {@link org.eclipse.xtend.lib.annotations.AccessorsProcessor}
 */
@Beta
class JsonAccessorsProcessor implements TransformationParticipant<MutableMemberDeclaration> {

	override doTransform(List<? extends MutableMemberDeclaration> elements, extension TransformationContext context) {
		elements.forEach[transform(context)]
	}

	def dispatch void transform(MutableFieldDeclaration it, extension TransformationContext context) {
		extension val util = new JsonAccessorsProcessor.Util(context)
		if (shouldAddGetter) {
			addGetter(getterType.toVisibility)
		}
		if (shouldAddSetter) {
			addSetter(setterType.toVisibility)
		}
	}

	def dispatch void transform(MutableClassDeclaration it, extension TransformationContext context) {
		if (findAnnotation(Data.findTypeGlobally) !== null) {
			return
		}
		val extension requiredArgsUtil = new org.eclipse.xtend.lib.annotations.FinalFieldsConstructorProcessor.Util(
			context)
		if (needsFinalFieldConstructor || findAnnotation(FinalFieldsConstructor.findTypeGlobally) !== null) {
			addFinalFieldsConstructor
		}
		declaredFields.filter[!static && thePrimaryGeneratedJavaElement].forEach[_transform(context)]
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

		new(TransformationContext context) {
			this.context = context
		}

		def toVisibility(AccessorType type) {
			switch type {
				case PUBLIC_GETTER: Visibility.PUBLIC
				case PROTECTED_GETTER: Visibility.PROTECTED
				case PACKAGE_GETTER: Visibility.DEFAULT
				case PRIVATE_GETTER: Visibility.PRIVATE
				case PUBLIC_SETTER: Visibility.PUBLIC
				case PROTECTED_SETTER: Visibility.PROTECTED
				case PACKAGE_SETTER: Visibility.DEFAULT
				case PRIVATE_SETTER: Visibility.PRIVATE
				default: throw new IllegalArgumentException('''Cannot convert «type»''')
			}
		}

		def hasGetter(FieldDeclaration it) {
			possibleGetterNames.exists[name|declaringType.findDeclaredMethod(name) !== null]
		}

		def shouldAddGetter(FieldDeclaration it) {
			!hasGetter && getterType !== AccessorType.NONE
		}

		def getGetterType(FieldDeclaration it) {
			val annotation = accessorsAnnotation ?: declaringType.accessorsAnnotation
			if (annotation !== null) {
				val types = annotation.getEnumArrayValue("value").map[AccessorType.valueOf(simpleName)]
				return types.findFirst[name.endsWith("GETTER")] ?: AccessorType.NONE
			}
			return null;
		}

		def getAccessorsAnnotation(AnnotationTarget it) {
			findAnnotation(Accessors.findTypeGlobally)
		}

		def validateGetter(MutableFieldDeclaration field) {
		}

		def getGetterName(FieldDeclaration it) {
			possibleGetterNames.head
		}

		def List<String> getPossibleGetterNames(FieldDeclaration it) {
			val names = newArrayList
			// common case: a boolean field already starts with 'is'. Allow field name as getter method name
			if (type.orObject.isBooleanType && simpleName.startsWith('is') && simpleName.length > 2 &&
				Character.isUpperCase(simpleName.charAt(2))) {
				names += simpleName
			}
			names.addAll((if(type.orObject.isBooleanType) #["is", "get"] else #["get"]).map [ prefix |
				prefix + simpleName.toFirstUpper
			])
			return names
		}

		def isBooleanType(TypeReference it) {
			!inferred && it == primitiveBoolean
		}

		def void addGetter(MutableFieldDeclaration field, Visibility visibility) {
			field.validateGetter
			field.markAsRead
			field.declaringType.addMethod(field.getterName) [

				primarySourceElement = field.primarySourceElement

				addAnnotation(
					this.context.newAnnotationReference(
						JsonProperty,
						[ a |
							a.set("value", fieldNameExtractor.jsonParamName(field, this.context))
						]
					)
				)
				returnType = field.type.orObject
				body = '''return «field.fieldOwner».«field.simpleName»;'''
				static = field.static
				it.visibility = visibility
			]
		}

		def getSetterType(FieldDeclaration it) {
			val annotation = accessorsAnnotation ?: declaringType.accessorsAnnotation
			if (annotation !== null) {
				val types = annotation.getEnumArrayValue("value").map[AccessorType.valueOf(simpleName)]
				return types.findFirst[name.endsWith("SETTER")] ?: AccessorType.NONE
			}
			return null
		}

		private def fieldOwner(MutableFieldDeclaration it) {
			if(static) declaringType.newTypeReference else "this"
		}

		def hasSetter(FieldDeclaration it) {
			declaringType.findDeclaredMethod(setterName, type.orObject) !== null
		}

		def getSetterName(FieldDeclaration it) {
			"set" + simpleName.toFirstUpper
		}

		def shouldAddSetter(FieldDeclaration it) {
			!final && !hasSetter && setterType !== AccessorType.NONE
		}

		def validateSetter(MutableFieldDeclaration field) {
			if (field.final) {
				field.addError("Cannot set a final field")
			}
			if (field.type === null || field.type.inferred) {
				field.addError("Type cannot be inferred.")
				return
			}
		}

		def void addSetter(MutableFieldDeclaration field, Visibility visibility) {
			field.validateSetter
			field.declaringType.addMethod(field.setterName) [
				primarySourceElement = field.primarySourceElement
				returnType = primitiveVoid
				val param = addParameter(field.simpleName, field.type.orObject)
				body = '''«field.fieldOwner».«field.simpleName» = «param.simpleName»;'''
				static = field.static
				it.visibility = visibility
			]
		}

		private def orObject(TypeReference ref) {
			if(ref === null) object else ref
		}
	}

}

/**
 * Creates getters and setters for annotated fields or for all fields in an annotated class.
 * <p>
 * Annotated on a field
 * <ul>
 * <li>Creates a getter for that field if none exists. For primitive boolean properties, the "is"-prefix is used.</li>
 * <li>Creates a setter for that field if it is not final and no setter exists</li>
 * <li>By default the accessors are public</li>
 * <li>If the {@link AccessorType}[] argument is given, only the listed
 * accessors with the specified visibility will be generated</li>
 * </ul>
 * </p>
 * <p>
 * Annotated on a class
 * <ul>
 * <li>Creates accessors for all non-static fields of that class as specified
 * above</li>
 * <li>Creates a constructor taking all final fields of the class if no
 * constructor exists yet. If there already is a constructor and you want the
 * default one on top of that, you can use the {@link FinalFieldsConstructor}
 * annotation.</li>
 * </ul>
 * </p>
 * Field-level annotations have precedence over a class-level annotation. Accessors can be suppressed completely by using {@link AccessorType#NONE}.
 * This annotation can also be used to fine-tune the getters generated by {@link Data}.
 * @since 2.7
 */
@GwtCompatible
@Target(#[ElementType.FIELD, ElementType.TYPE])
@Active(JsonAccessorsProcessor)
@Documented
annotation Accessors {
	/**
	 * Describes the access modifiers for generated accessors. Valid combinations
	 * include at most one type for getters and one for setters.
	 * Accessors may be suppressed by passing {@link AccessorType#NONE}.
	 */
	AccessorType[] value = #[AccessorType.PUBLIC_GETTER, AccessorType.PUBLIC_SETTER]
}

/**
 * @since 2.7
 * @noreference
 */
@Beta
@GwtCompatible
enum AccessorType {
	PUBLIC_GETTER,
	PROTECTED_GETTER,
	PACKAGE_GETTER,
	PRIVATE_GETTER,
	PUBLIC_SETTER,
	PROTECTED_SETTER,
	PACKAGE_SETTER,
	PRIVATE_SETTER,
	NONE
}
