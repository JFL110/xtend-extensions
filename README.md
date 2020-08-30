# xtend-extensions
[![Java CI](https://github.com/JFL110/xtend-extensions/workflows/Java%20CI/badge.svg?x=y)](https://github.com/JFL110/xtend-extensions/actions) [![codecov](https://codecov.io/gh/JFL110/xtend-extensions/branch/master/graph/badge.svg?x=y)](https://codecov.io/gh/JFL110/xtend-extensions) [![Publish Github Packages](https://github.com/JFL110/xtend-extensions/workflows/Publish%20Github%20Packages/badge.svg?x=y)](https://github.com/JFL110/xtend-extensions/actions?query=workflow%3A%22Publish+Github+Packages%22)

Utilities for code generation using [Java Xtend](https://github.com/eclipse/xtext-xtend).

## Immutable JSON Data Transfer Objects

Create Jackson annotated classes with ```@JsonData``` and ```@JsonDataField```. For example, replace the boilerplate heavy:
```
public class Message {
  
  private final long time;
  private final String text;

  @JsonConstructor
  public Message(@JsonProperty("time") long time, @JsonProperty("text")  String text){
    this.time = time;
    this.text = text;
  }
  
  
  @JsonProperty("time")
  public long getTime(){
    return time;
  }
  
  @JsonProperty("text")
  public String getText(){
    return text;
  }
}
```

with:

```
@JsonData class Message {

 @JsonDataField("time") long time;
 @JsonDataField("time") String text;

}
```
