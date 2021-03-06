package org.jfl110.xtend

import com.google.common.annotations.Beta
import com.google.common.annotations.GwtCompatible
import java.lang.annotation.ElementType
import java.lang.annotation.Target
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.AnnotationReference
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.FieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.annotations.Data

/**
 * Modified copy of {@link org.eclipse.xtend.lib.annotations.ToStringProcessor} 
 * with references to Xtend libs removed from output
 */
@Beta
@Target(ElementType.TYPE)
@Active(ToStringProcessor)
@GwtCompatible
annotation ToString {
	/**
	 * Fields with null values are not shown in the output.
	 */
	val skipNulls = false
	/**
	 * Seperate fields with a comma and a single space
	 */
	val singleLine = false
	/**
	 * Only list the values of the fields, not their names
	 */
	val hideFieldNames = false

	/**
	 * By default, Iterables, Arrays and multiline Strings are pretty-printed.
	 * Switching to their normal representation makes the toString method significantly faster.
	 * @since 2.9
	 */
	val verbatimValues = false
}

/**
 * @since 2.7
 * @noextend This class is not intended to be subclassed by clients.
 * @noreference This class is not intended to be referenced by clients.
 * @noinstantiate This class is not intended to be instantiated by clients.
 */
@Beta
class ToStringConfiguration {
	val boolean skipNulls
	val boolean singleLine
	val boolean hideFieldNames
	val boolean verbatimValues

	new() {
		this(false, false, false, false)
	}

	new(boolean skipNulls, boolean singleLine, boolean hideFieldNames, boolean verbatimValues) {
		this.skipNulls = skipNulls
		this.singleLine = singleLine
		this.hideFieldNames = hideFieldNames
		this.verbatimValues = verbatimValues
	}

	new(AnnotationReference annotation) {
		this.skipNulls = annotation.getBooleanValue("skipNulls")
		this.singleLine = annotation.getBooleanValue("singleLine")
		this.hideFieldNames = annotation.getBooleanValue("hideFieldNames")
		this.verbatimValues = annotation.getBooleanValue("verbatimValues")
	}

	def isSkipNulls() {
		skipNulls
	}

	def isSingleLine() {
		singleLine
	}

	def isHideFieldNames() {
		hideFieldNames
	}

	def isVerbatimValues() {
		verbatimValues
	}
}

/**
 * @since 2.7
 * @noextend
 * @noreference
 */
@Beta
class ToStringProcessor extends AbstractClassProcessor {

	override doTransform(MutableClassDeclaration it, extension TransformationContext context) {
		if(findAnnotation(Data.findTypeGlobally) !== null) {
			return
		}
		val extension util = new ToStringProcessor.Util(context)
		val annotation = findAnnotation(ToString.findTypeGlobally)
		val configuration = new ToStringConfiguration(annotation)
		if(hasToString) {
			annotation.addWarning("toString is already defined, this annotation has no effect.")
		} else {
			addToString(declaredFields.filter[thePrimaryGeneratedJavaElement && ! static && !transient], configuration)
		}
	}

	/**
	 * @since 2.7
	 * @noextend
	 * @noreference
	 */
	@Beta
	static class Util {
		extension TransformationContext context

		new(TransformationContext context) {
			this.context = context
		}

		def hasToString(ClassDeclaration it) {
			findDeclaredMethod("toString") !== null
		}

		def getToStringConfig(ClassDeclaration it) {
			val anno = findAnnotation(ToString.findTypeGlobally)
			if(anno === null) null else new ToStringConfiguration(anno)
		}

		def void addToString(MutableClassDeclaration cls, Iterable<? extends FieldDeclaration> fields, ToStringConfiguration config) {
			cls.addMethod("toString") [
				primarySourceElement = cls.primarySourceElement
				returnType = string
				addAnnotation(newAnnotationReference(Override))
				body = '''
					java.lang.StringBuilder b = new java.lang.StringBuilder().append("[");
					«FOR field : fields»
						b = b.append("«field.simpleName»=").append(this.«field.simpleName»).append(" ");
					«ENDFOR»
					return b.append("]").toString();
				'''
			]
		}
	}
}
