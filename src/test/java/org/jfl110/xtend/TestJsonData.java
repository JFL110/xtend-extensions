package org.jfl110.xtend;

import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import org.eclipse.xtend.core.compiler.batch.XtendCompilerTester;
import org.junit.Test;

public class TestJsonData {

	private static final String ENCODING = "UTF8";
	private final XtendCompilerTester compile = XtendCompilerTester.newXtendCompilerTester(getClass().getClassLoader());

	@Test
	public void testCases() throws Exception {
		runTestCase("JsonDataTestBeanOne.xtend.input.txt", "JsonDataTestBeanOne.java.output.txt");
		runTestCase("JsonDataTestBeanTwo.xtend.input.txt", "JsonDataTestBeanTwo.java.output.txt");
		runTestCase("JsonDataTestBeanPublicField.xtend.input.txt", "JsonDataTestBeanPublicField.java.output.txt");
		runTestCase("JsonDataTestBeanNoFinal.xtend.input.txt", "JsonDataTestBeanNoFinal.java.output.txt");
		runTestCase("JsonDataTestBeanComments.xtend.input.txt", "JsonDataTestBeanComments.java.output.txt");
	}


	/**
	 * Compare the input Xtend source and assert it matches the output Java source
	 */
	private void runTestCase(String testFile, String expectedOutputFile) throws Exception {
		String input = readFileAsString(testFile);
		String expectedOutput = readFileAsString(expectedOutputFile);
		compile.assertCompilesTo(input, expectedOutput);
	}


	/**
	 * File -> String
	 */
	private String readFileAsString(String testResourceFile) throws Exception {
		URL url = getClass().getClassLoader().getResource("./" + testResourceFile);
		Path resPath = Paths.get(url.toURI());
		return new String(Files.readAllBytes(resPath), ENCODING);
	}
}