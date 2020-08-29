package org.jfl110.xtend;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 
 * 
 * See {@link org.jfl110.xtend.JsonData}
 */
@Target(ElementType.FIELD)
@SuppressWarnings("all")
@Retention(RetentionPolicy.SOURCE)
public @interface JsonDataField {
	String value();
}