using System;
using Xunit;

namespace HelloWorld.Tests
{
    public class HelloWorldTests
    {
        [Fact]
        public void SayHelloTest()
        {
            Assert.Equal("Hello World!", HelloWorld.App.HelloWorld.SayHello());
        }
    }
}
