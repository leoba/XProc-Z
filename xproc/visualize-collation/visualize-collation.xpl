<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:vc="https://github.com/leoba/VisColl" >
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<p:import href="../xproc-z-library.xpl"/>
	
	
	
	<p:declare-step type="vc:visualize-collation" name="visualize-collation">
		<p:input port="source" primary="true"/>
		<p:input port="parameters" kind="parameter" primary="true"/>
		<p:output port="result" primary="true" sequence="true"/>
		<p:option name="relative-uri" select=" '' "/>
		<p:variable name="tei-prefix" select="/c:request/c:multipart/c:body[contains(@disposition,concat('name=', codepoints-to-string(34), 'tei-prefix', codepoints-to-string(34)))]"/>
		<p:choose>
			<p:when test="not(/c:request/c:multipart)">
				<!-- No files were uploaded -->
				<!-- Return a form for the user to upload data files -->
				<p:load href="upload-form.html"/>
				<z:make-http-response/>
			</p:when>
			<p:otherwise>
				
				<!-- User uploaded files - process and return them -->
				<!-- 
					The manuscript is the content of the /c:request/c:multipart/c:body 
					whose @disposition starts with 'form-data; name="collation-model"' 
				-->
				<z:get-file-upload name="collation-model" field-name="collation-model"/>
				<!-- process the manuscript -->
				<vc:transform xslt="process4.xsl" name="process4"/>
				<vc:transform xslt="process5.xsl" name="process5"/>

				<!-- merge the transformed collation-model and the spreadsheet into a single				
				document and pass it to the resulting couple of transforms -->
				<z:get-file-upload name="image-list" field-name="image-list">
					<p:input port="source">
						<p:pipe port="source" step="visualize-collation"/>
					</p:input>
				</z:get-file-upload>
				<p:wrap-sequence wrapper="manuscript-and-images" name="manuscript-and-images">
					<p:input port="source">
						<p:pipe step="process5" port="result"/>
						<p:pipe step="image-list" port="result"/>
					</p:input>
				</p:wrap-sequence>
				<!--<vc:transform xslt="process6-excel.xsl"/>-->
				<p:xslt>
					<p:input port="stylesheet">
						<p:document href="process6-excel.xsl"/>
					</p:input>
					<p:with-param name="tei-prefix" select="$tei-prefix"/>
				</p:xslt>
				<p:xslt name="process7" output-base-uri="file:/">
					<p:input port="stylesheet">
						<p:document href="process7.xsl"/>
					</p:input>
				</p:xslt>	
                <p:group name="debugging-dump-intermediate-stages">
					<p:store href="process4.xml">
						<p:input port="source">
							<p:pipe step="process4" port="result"/>
						</p:input>
					</p:store>
					<p:store href="process5.xml">
						<p:input port="source">
							<p:pipe step="process5" port="result"/>
						</p:input>
					</p:store>
					<p:store href="manuscript-and-images.xml">
						<p:input port="source">
							<p:pipe step="manuscript-and-images" port="result"/>
						</p:input>
					</p:store>
					<!--
					<p:store href="process6.xml">
						<p:input port="source">
							<p:pipe step="process6" port="result"/>
						</p:input>
					</p:store>
					-->
				</p:group>
                <p:count>
					<p:input port="source">
						<p:pipe step="process7" port="secondary"/>
					</p:input>
				</p:count>
                <p:choose>
					<p:when test="/c:result=0">
						<z:not-found/>
					</p:when>
					<p:otherwise>
				<z:zip-sequence>
					<p:input port="source">
						<p:pipe step="process7" port="secondary"/>
					</p:input>
				</z:zip-sequence>
				<!-- Return the ZIP file to the browser -->
				<p:template name="http-response">
					<p:input port="template">
						<p:inline>
							<c:response status="200">
								<c:header name="X-Powered-By" value="XProc using XML Calabash"/>
								<c:header name="Server" value="XProc-Z"/>
								<c:body 
									content-type="{/c:body/@content-type}" 
									disposition="attachment; filename='VisColl.zip'" 
									encoding="{/c:body/@encoding}">{/c:body/node()}</c:body>
							</c:response>
						</p:inline>
					</p:input>
				</p:template>
</p:otherwise>
</p:choose>
			</p:otherwise>
		</p:choose>
	</p:declare-step>
	
	
	
	<!-- shorthand for executing an XSLT  -->
	<p:declare-step type="vc:transform" name="transform">
		
		<p:input port="source"/>
		<p:output port="result" primary="true"/>
		<p:input port="parameters" kind="parameter"/>
		
		<p:option name="xslt" required="true"/>
		
		<p:load name="load-stylesheet">
			<p:with-option name="href" select="$xslt"/>
		</p:load>
		
		<p:xslt name="execute-xslt">
			<p:input port="source">
				<p:pipe step="transform" port="source"/>
			</p:input>
			<p:input port="stylesheet">
				<p:pipe step="load-stylesheet" port="result"/>
			</p:input>
		</p:xslt>
	</p:declare-step>
</p:library>
