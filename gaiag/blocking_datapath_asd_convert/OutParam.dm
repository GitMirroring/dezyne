<?xml version="1.0"?>
<asd OmVersion="10.10.0" BackwardOmVersion="10.10.0" Serializer="2" >
	<DesignModel ID="893071">
		<CodeGenerationLanguage>cpp</CodeGenerationLanguage>
		<CodeGenerationVersion>9.2.9</CodeGenerationVersion>
		<DateCreated>20151021T162910</DateCreated>
		<DateModified>20151105T124736</DateModified>
		<Description>Basis&#32;for&#32;testing&#32;parameter&#32;passing.</Description>
		<Guid>ADA478BDA88B485AB5FA8EE48A1E37D0</Guid>
		<ModelSignature>BASE64_de6kCBzSmrTCpiisMOyMs6rNGahkfDL4iucbJKdh/1hA5Th8mk/S61nPDxEpFwy59LWsauigMqZK8gO6hBk7Wknrd78iv8WmX4IFuNQWQ7PkCfLKqiyt0WRkkFHNEuGu6rj0R+hofT1gXO0RlZTFTVVO7+oDCBm5F+ZXkrIhIU4GPjCd+2mQFtqbkVDzB4drg0J/QtjMy9O6BmC+aAW83EqNXFh0cAohMAQYAm+ygwHmpZ3GtRmYgRNMPzhPKvP73e6NWJ1a+UDDExlnivW/ks/9M8cz97YiUbVFKQSGXvCEMBcdOLK4Izwz5IiaDu9Pxw+WMz/LcCiwnbO6oj1BYQ==</ModelSignature>
		<Name>OutParam</Name>
		<ToolVersion>ASD:Suite&#32;ModelBuilder&#32;9.2.3(52305)</ToolVersion>
		<AbstractInterface>
			<AbstractInterface ID="893072">
				<Guid>C87A6402319E4BBABE71CE5B8DC9EACF</Guid>
				<Events>
					<CallEvent ID="893073">
						<Guid>D849ADC0EF514853A0CF4F74E848898A</Guid>
						<Name>StateInvariant</Name>
					</CallEvent>
					<CallEvent ID="893074">
						<Guid>84DEE61F60034238A1EDEC85D19FEA49</Guid>
						<Name>DataInvariant</Name>
					</CallEvent>
				</Events>
				<ReplyEvents>
					<ReplyEvent ID="893075">
						<Guid>EAE2E4DB6FAA4E7681E63D799063AD7D</Guid>
						<Name>NoOp</Name>
					</ReplyEvent>
					<ReplyEvent ID="893076">
						<Guid>8F0CD6C16E1B453883CBC5F7326E1867</Guid>
						<Name>Illegal</Name>
					</ReplyEvent>
					<ReplyEvent ID="893077">
						<Guid>6056DBEB478C4BC0A9C08D1BFB76413D</Guid>
						<Name>Blocked</Name>
					</ReplyEvent>
				</ReplyEvents>
			</AbstractInterface>
		</AbstractInterface>
		<BuiltInInterface>
			<BuiltInInterface ID="893078">
				<Guid>CDB0F64B073F42E88091147C025CD88F</Guid>
				<Events>
					<CallEvent ID="893079">
						<Guid>F29EFB83ED53409d84B64CF57ED6A0F4</Guid>
						<Name>Subscribe</Name>
						<Parameters>
							<USRInterfaceParameter ID="893080">
							</USRInterfaceParameter>
						</Parameters>
					</CallEvent>
					<CallEvent ID="893081">
						<Guid>25B76D8404B54f1d8EA5FF22E47C7CE5</Guid>
						<Name>Unsubscribe</Name>
						<Parameters>
							<USRInterfaceParameter ID="893082">
							</USRInterfaceParameter>
						</Parameters>
					</CallEvent>
					<CallEvent ID="893083">
						<Guid>8CB0CCD035084481B76B3EC0A974FBF5</Guid>
						<Name>Initialise</Name>
						<Parameters>
							<SimpleParameter ID="893084">
								<Direction>pdInOut</Direction>
								<Name>dataVariable</Name>
								<Type>any</Type>
							</SimpleParameter>
						</Parameters>
					</CallEvent>
					<CallEvent ID="893085">
						<Guid>444DBCA038BD4EB3AB79CDBF6E531334</Guid>
						<Name>Invalidate</Name>
						<Parameters>
							<SimpleParameter ID="893086">
								<Direction>pdInOut</Direction>
								<Name>dataVariable</Name>
								<Type>any</Type>
							</SimpleParameter>
						</Parameters>
					</CallEvent>
				</Events>
				<ReplyEvents>
					<ReplyEvent ID="893087">
						<Guid>4689006D1E9D4B5F9F33EE46C7414D81</Guid>
						<Name>VoidReply</Name>
					</ReplyEvent>
				</ReplyEvents>
			</BuiltInInterface>
		</BuiltInInterface>
		<CodeGeneratorSettings>
			<CodeGenInfo ID="893167">
				<Language>c</Language>
				<UseOldTracing>1</UseOldTracing>
				<UseServiceNameInQualifiedNames>0</UseServiceNameInQualifiedNames>
			</CodeGenInfo>
			<CodeGenInfo ID="893168">
				<Language>cpp</Language>
				<UseOldTracing>1</UseOldTracing>
				<UseServiceNameInQualifiedNames>0</UseServiceNameInQualifiedNames>
			</CodeGenInfo>
			<CodeGenInfo ID="893169">
				<Language>csharp</Language>
				<UseOldTracing>1</UseOldTracing>
				<UseServiceNameInQualifiedNames>0</UseServiceNameInQualifiedNames>
			</CodeGenInfo>
			<CodeGenInfo ID="893170">
				<Language>csp</Language>
				<UseOldTracing>1</UseOldTracing>
				<UseServiceNameInQualifiedNames>0</UseServiceNameInQualifiedNames>
			</CodeGenInfo>
			<CodeGenInfo ID="893171">
				<Language>java</Language>
				<UseOldTracing>1</UseOldTracing>
				<UseServiceNameInQualifiedNames>0</UseServiceNameInQualifiedNames>
			</CodeGenInfo>
			<CodeGenInfo ID="893172">
				<Language>tinyc</Language>
				<UseOldTracing>1</UseOldTracing>
				<UseServiceNameInQualifiedNames>0</UseServiceNameInQualifiedNames>
			</CodeGenInfo>
		</CodeGeneratorSettings>
		<DataVariables>
			<DataVariable ID="893173">
				<AutoIniOption>ainiConstruction</AutoIniOption>
				<Guid>7F4796FC899841E3BB80DECAEA5C834C</Guid>
				<Name>nr</Name>
			</DataVariable>
		</DataVariables>
		<ImplementedService>
			<ServiceDependency ID="893088">
				<ModelGuid>F05429D0D87E49149B26D516CB1D4ABB</ModelGuid>
				<Name>OutParam</Name>
				<RelativePath>OutParam.im</RelativePath>
				<Declaration>
					<ServiceDeclaration ID="893089">
						<ApplicationInterfaces>
							<ApplicationInterface ID="893090">
								<Guid>5190707EE7884D77844172EB0E71348C</Guid>
								<Name>IOutParam</Name>
								<Events>
									<CallEvent ID="893091">
										<Guid>FC29533B6FED41BA99053D1C64B6D58A</Guid>
										<Name>e_out</Name>
										<Parameters>
											<SimpleParameter ID="893092">
												<Name>number</Name>
											</SimpleParameter>
										</Parameters>
									</CallEvent>
									<CallEvent ID="893375">
										<Guid>55D07D11B6D843CB85781901F4BCADF1</Guid>
										<Name>e_out_sync</Name>
										<Parameters>
											<SimpleParameter ID="893376">
												<Name>number</Name>
											</SimpleParameter>
										</Parameters>
									</CallEvent>
									<CallEvent ID="893174">
										<Guid>E855C63A38304D3EBE26509C7A95C90F</Guid>
										<Name>e_out_async</Name>
										<Parameters>
											<SimpleParameter ID="893175">
												<Name>number</Name>
											</SimpleParameter>
										</Parameters>
									</CallEvent>
									<CallEvent ID="893093">
										<Guid>77EFA1161F0F45FDA3075F83FF7904CC</Guid>
										<Name>e_inout</Name>
										<Parameters>
											<SimpleParameter ID="893094">
												<Name>number</Name>
											</SimpleParameter>
										</Parameters>
									</CallEvent>
									<CallEvent ID="893377">
										<Guid>A2E8EB4A9FFC46E38C8833DEC9F61D80</Guid>
										<Name>e_inout_sync</Name>
										<Parameters>
											<SimpleParameter ID="893378">
												<Name>number</Name>
											</SimpleParameter>
										</Parameters>
									</CallEvent>
									<CallEvent ID="893176">
										<Guid>31D229E44ADF47CFBF69F6F9CAF04655</Guid>
										<Name>e_inout_async</Name>
										<Parameters>
											<SimpleParameter ID="893177">
												<Name>number</Name>
											</SimpleParameter>
										</Parameters>
									</CallEvent>
									<CallEvent ID="893178">
										<Guid>D4B0528678F04889998961CB035A4025</Guid>
										<Name>e_outdated</Name>
										<Parameters>
											<SimpleParameter ID="893179">
												<Name>number</Name>
											</SimpleParameter>
										</Parameters>
									</CallEvent>
								</Events>
								<ReplyEvents>
									<ReplyEvent ID="893095">
										<Guid>C98E0770A3CB4CDF9820DC78A78B089B</Guid>
										<Name>VoidReply</Name>
									</ReplyEvent>
								</ReplyEvents>
							</ApplicationInterface>
						</ApplicationInterfaces>
					</ServiceDeclaration>
				</Declaration>
			</ServiceDependency>
		</ImplementedService>
		<MainMachine>
			<MainMachine ID="893096">
				<Guid>6EE205538C9C4D858B74960BFC5CC7AB</Guid>
				<Name>OutParam</Name>
				<StateVariables>
					<StateVariable ID="893180">
						<Guid>D06FE26CB64B411CA52E7F56CB9F40D3</Guid>
						<InitialValue>false</InitialValue>
						<Name>pending_reply</Name>
						<VarType>svtBool</VarType>
					</StateVariable>
					<StateVariable ID="893181">
						<Guid>A5CF8D9F172B4F0BA07E2E0A6A8ADCBD</Guid>
						<InitialValue>false</InitialValue>
						<Name>synchronous</Name>
						<VarType>svtBool</VarType>
					</StateVariable>
					<StateVariable ID="893379">
						<Guid>1CAFF0B10B2C48EEAF30CB0B2C255ED2</Guid>
						<InitialValue>false</InitialValue>
						<Name>synchronous_cb</Name>
						<VarType>svtBool</VarType>
					</StateVariable>
				</StateVariables>
				<States>
					<State ID="893097">
						<Guid>08D898919FCC4D57AE9E8CAFAA880642</Guid>
						<Name>Available</Name>
						<Rules>
							<Rule ID="893098">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="893099">
										<Row>2</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893100">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="893101">
										<Row>3</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893102">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="893103">
										<Comment>Reply&#32;at&#32;end&#32;of&#32;transaction</Comment>
										<Row>4</Row>
										<StateUpdate>pending_reply&#32;=&#32;true;&#10;synchronous&#32;=&#32;true;&#10;synchronous_cb&#32;=&#32;false</StateUpdate>
										<NextState>893182</NextState>
										<Actions>
											<Action ID="893183">
												<Event>893184</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893185">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893105">
												<Value>&lt;&lt;nr</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893380">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="893381">
										<Comment>Reply&#32;at&#32;end&#32;of&#32;transaction</Comment>
										<Row>5</Row>
										<StateUpdate>pending_reply&#32;=&#32;true;&#10;synchronous&#32;=&#32;true;&#10;synchronous_cb&#32;=&#32;true</StateUpdate>
										<NextState>893182</NextState>
										<Actions>
											<Action ID="893382">
												<Event>893184</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893383">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893384">
												<Value>&lt;&lt;nr</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893187">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="893188">
										<Comment>Reply&#32;at&#32;end&#32;of&#32;transaction</Comment>
										<Row>6</Row>
										<StateUpdate>pending_reply&#32;=&#32;true;&#10;synchronous&#32;=&#32;false;&#10;synchronous_cb&#32;=&#32;false</StateUpdate>
										<NextState>893182</NextState>
										<Actions>
											<Action ID="893189">
												<Event>893184</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893190">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893191">
												<Value>&lt;&lt;nr</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893106">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="893107">
										<Comment>Reply&#32;at&#32;end&#32;of&#32;transaction</Comment>
										<Row>7</Row>
										<StateUpdate>pending_reply&#32;=&#32;true;&#10;synchronous&#32;=&#32;true;&#10;synchronous_cb&#32;=&#32;false</StateUpdate>
										<NextState>893182</NextState>
										<Actions>
											<Action ID="893192">
												<Event>893184</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893193">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893194">
												<Value>&gt;&lt;nr</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893385">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="893386">
										<Comment>Reply&#32;at&#32;end&#32;of&#32;transaction</Comment>
										<Row>8</Row>
										<StateUpdate>pending_reply&#32;=&#32;true;&#10;synchronous&#32;=&#32;true;&#10;synchronous_cb&#32;=&#32;true</StateUpdate>
										<NextState>893182</NextState>
										<Actions>
											<Action ID="893387">
												<Event>893184</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893388">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893389">
												<Value>&gt;&lt;nr</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893195">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="893196">
										<Comment>Reply&#32;at&#32;end&#32;of&#32;transaction</Comment>
										<Row>9</Row>
										<StateUpdate>pending_reply&#32;=&#32;true;&#10;synchronous&#32;=&#32;false;&#10;synchronous_cb&#32;=&#32;false</StateUpdate>
										<NextState>893182</NextState>
										<Actions>
											<Action ID="893197">
												<Event>893184</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893198">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893348">
												<Value>&gt;&lt;nr</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893200">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="893201">
										<Comment>Early&#32;Reply&#32;ensures&#32;output&#32;parameter&#32;not&#32;modified&#32;after&#32;this&#32;point.</Comment>
										<Row>10</Row>
										<StateUpdate>pending_reply&#32;=&#32;false;&#10;synchronous&#32;=&#32;true</StateUpdate>
										<NextState>893182</NextState>
										<Actions>
											<Action ID="893202">
												<Event>893095</Event>
											</Action>
											<Action ID="893203">
												<Event>893184</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893204">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893205">
												<Value>&lt;&lt;nr</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893206">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893208">
										<Row>11</Row>
										<Actions>
											<Action ID="893209">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893210">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893212">
										<Row>12</Row>
										<Actions>
											<Action ID="893213">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893214">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="893182">
						<Guid>2B12AA4946CC489BAE7FF71A19E0575E</Guid>
						<Name>WaitInit</Name>
						<Rules>
							<Rule ID="893215">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="893216">
										<Row>14</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893217">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="893218">
										<Row>15</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893219">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="893220">
										<Row>16</Row>
										<Actions>
											<Action ID="893221">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893222">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893390">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="893391">
										<Row>17</Row>
										<Actions>
											<Action ID="893392">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893393">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893223">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="893224">
										<Row>18</Row>
										<Actions>
											<Action ID="893225">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893226">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893227">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="893228">
										<Row>19</Row>
										<Actions>
											<Action ID="893229">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893230">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893394">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="893395">
										<Row>20</Row>
										<Actions>
											<Action ID="893396">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893397">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893231">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="893232">
										<Row>21</Row>
										<Actions>
											<Action ID="893233">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893234">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893235">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="893236">
										<Row>22</Row>
										<Actions>
											<Action ID="893237">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893238">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893239">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893240">
										<Guard>synchronous&#32;and&#32;not&#32;synchronous_cb</Guard>
										<Row>23</Row>
										<NextState>893241</NextState>
										<Actions>
											<Action ID="893242">
												<Event>893243</Event>
												<Arguments>
													<SimpleArgument ID="893244">
														<Value>&gt;&gt;nr</Value>
													</SimpleArgument>
												</Arguments>
												<USRExpression>
													<ServiceReferenceExpression ID="893245">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
									<RuleCase ID="893398">
										<Guard>synchronous&#32;and&#32;synchronous_cb</Guard>
										<Row>24</Row>
										<NextState>893247</NextState>
										<Actions>
											<Action ID="893399">
												<Event>893361</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893400">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
									<RuleCase ID="893246">
										<Guard>otherwise</Guard>
										<Row>25</Row>
										<NextState>893247</NextState>
										<Actions>
											<Action ID="893248">
												<Event>893249</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893250">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893251">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893252">
										<Row>26</Row>
										<Actions>
											<Action ID="893253">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893254">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="893247">
						<Comment>pending_reply&#32;==&#32;true</Comment>
						<Guid>D9FD87C3E3EA45A1980A327315C3FACF</Guid>
						<Name>WaitReceive</Name>
						<Rules>
							<Rule ID="893255">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="893256">
										<Row>41</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893257">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="893258">
										<Row>42</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893259">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="893260">
										<Row>43</Row>
										<Actions>
											<Action ID="893261">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893262">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893401">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="893402">
										<Row>44</Row>
										<Actions>
											<Action ID="893403">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893404">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893263">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="893264">
										<Row>45</Row>
										<Actions>
											<Action ID="893265">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893266">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893267">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="893268">
										<Row>46</Row>
										<Actions>
											<Action ID="893269">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893270">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893405">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="893406">
										<Row>47</Row>
										<Actions>
											<Action ID="893407">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893408">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893271">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="893272">
										<Row>48</Row>
										<Actions>
											<Action ID="893273">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893274">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893275">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="893276">
										<Row>49</Row>
										<Actions>
											<Action ID="893277">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893278">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893279">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893280">
										<Row>50</Row>
										<Actions>
											<Action ID="893281">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893282">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893283">
										<Row>51</Row>
										<StateUpdate>pending_reply&#32;=&#32;false;&#10;synchronous_cb&#32;=&#32;false</StateUpdate>
										<NextState>893097</NextState>
										<Actions>
											<Action ID="893284">
												<Event>893285</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893286">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
											<Action ID="893287">
												<Event>893095</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893288">
												<Value>&gt;&gt;nr</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="893241">
						<Guid>8D5CFCD4AA434556988749792C98B37C</Guid>
						<Name>WaitGet</Name>
						<Rules>
							<Rule ID="893289">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="893290">
										<Row>28</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893291">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="893292">
										<Row>29</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893293">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="893294">
										<Row>30</Row>
										<Actions>
											<Action ID="893295">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893296">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893409">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="893410">
										<Row>31</Row>
										<Actions>
											<Action ID="893411">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893412">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893297">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="893298">
										<Row>32</Row>
										<Actions>
											<Action ID="893299">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893300">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893301">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="893302">
										<Row>33</Row>
										<Actions>
											<Action ID="893303">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893304">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893413">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="893414">
										<Row>34</Row>
										<Actions>
											<Action ID="893415">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893416">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893305">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="893306">
										<Row>35</Row>
										<Actions>
											<Action ID="893307">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893308">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893309">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="893310">
										<Row>36</Row>
										<Actions>
											<Action ID="893311">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893312">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893313">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893314">
										<Guard>pending_reply</Guard>
										<Row>37</Row>
										<StateUpdate>pending_reply&#32;=&#32;false</StateUpdate>
										<NextState>893097</NextState>
										<Actions>
											<Action ID="893315">
												<Event>893285</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893316">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
											<Action ID="893317">
												<Event>893095</Event>
											</Action>
										</Actions>
									</RuleCase>
									<RuleCase ID="893318">
										<Guard>otherwise</Guard>
										<Row>38</Row>
										<StateUpdate>pending_reply&#32;=&#32;false</StateUpdate>
										<NextState>893097</NextState>
										<Actions>
											<Action ID="893319">
												<Event>893285</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893320">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893321">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893322">
										<Row>39</Row>
										<Actions>
											<Action ID="893323">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893324">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
				</States>
			</MainMachine>
		</MainMachine>
		<ModelBuilderSettings>
			<ModelBuilderSettings ID="893110">
			</ModelBuilderSettings>
		</ModelBuilderSettings>
		<ServiceReferences>
			<ServiceReference ID="893186">
				<Construction>MultiStepOutParam</Construction>
				<Guid>EFDCA69F81B449C5B81C92DB7147B503</Guid>
				<Name>datasource</Name>
				<Dependency>893325</Dependency>
			</ServiceReference>
		</ServiceReferences>
		<UsedServices>
			<ServiceDependency ID="893325">
				<ModelGuid>EEE4517728214C438398964640490BA1</ModelGuid>
				<Name>MultiStepOutParam</Name>
				<RelativePath>MultiStepOutParam.im</RelativePath>
				<Declaration>
					<ServiceDeclaration ID="893326">
						<ApplicationInterfaces>
							<ApplicationInterface ID="893327">
								<Guid>2093145299A84913966963076B95FC08</Guid>
								<Name>IMultiStepOutParam</Name>
								<Used>1</Used>
								<Events>
									<CallEvent ID="893184">
										<Guid>2D1461BA0E8B44C4B95F2C584ABE9436</Guid>
										<Name>Init</Name>
										<ReplyType>rtValued</ReplyType>
									</CallEvent>
									<CallEvent ID="893285">
										<Guid>836B771245744261A051131B20D01CF8</Guid>
										<Name>Term</Name>
									</CallEvent>
									<CallEvent ID="893243">
										<Guid>7D27DA966C5C43CA95A58AA3404F41AF</Guid>
										<Name>GetData</Name>
										<ReplyType>rtValued</ReplyType>
										<Parameters>
											<SimpleParameter ID="893328">
												<Name>nr</Name>
											</SimpleParameter>
										</Parameters>
									</CallEvent>
									<CallEvent ID="893361">
										<Guid>7C3413B5A29A4A54A93045DA923C509B</Guid>
										<Name>GetData_SyncOutResult</Name>
									</CallEvent>
									<CallEvent ID="893249">
										<Guid>752D15711592462E92D09680B2B19C75</Guid>
										<Name>RequestData</Name>
									</CallEvent>
								</Events>
								<ReplyEvents>
									<ReplyEvent ID="893329">
										<Guid>E628FAB3AD564F8C8E582FADDD617434</Guid>
										<Name>VoidReply</Name>
									</ReplyEvent>
									<ReplyEvent ID="893207">
										<Guid>6EB319E13C6B4597A8493B37991FE882</Guid>
										<Name>Ok</Name>
									</ReplyEvent>
								</ReplyEvents>
							</ApplicationInterface>
						</ApplicationInterfaces>
						<NotificationInterfaces>
							<NotificationInterface ID="893330">
								<Guid>456CE0D97AE84222A17BF5CF63B2CC5D</Guid>
								<Name>IMultiStepOutParam_NI</Name>
								<Used>1</Used>
								<Events>
									<NotificationEvent ID="893211">
										<Guid>BB34CF3581DF43E39A5126DA6315B79B</Guid>
										<Name>ReceiveData</Name>
										<Parameters>
											<SimpleParameter ID="893331">
												<Name>number</Name>
											</SimpleParameter>
										</Parameters>
									</NotificationEvent>
								</Events>
							</NotificationInterface>
						</NotificationInterfaces>
					</ServiceDeclaration>
				</Declaration>
			</ServiceDependency>
		</UsedServices>
		<VerificationStatus>
			<VerificationStatus ID="893111">
				<CompilerVersion>9.2.9</CompilerVersion>
				<Language>cpp</Language>
				<Checks>
					<Check ID="893417">
						<CheckType>mvrSafety</CheckType>
						<Name>Modelling&#32;Error&#32;check</Name>
						<RelativePath>OutParam.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="893418">
						<CheckNo>1</CheckNo>
						<CheckType>mvrLivelock</CheckType>
						<Name>Livelock&#32;check</Name>
						<RelativePath>OutParam.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="893419">
						<CheckNo>2</CheckNo>
						<CheckType>mvrDeadlock</CheckType>
						<Name>Deadlock&#32;check</Name>
						<RelativePath>OutParam.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="893420">
						<CheckNo>3</CheckNo>
						<CheckType>mvrSafety</CheckType>
						<Name>Modelling&#32;Error&#32;check</Name>
						<RelativePath>MultiStepOutParam.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="893421">
						<CheckNo>4</CheckNo>
						<CheckType>mvrLivelock</CheckType>
						<Name>Livelock&#32;check</Name>
						<RelativePath>MultiStepOutParam.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="893422">
						<CheckNo>5</CheckNo>
						<CheckType>mvrDeadlock</CheckType>
						<Name>Deadlock&#32;check</Name>
						<RelativePath>MultiStepOutParam.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="893423">
						<CheckNo>6</CheckNo>
						<CheckType>mvrDeterminism</CheckType>
						<Name>Deterministic&#32;check</Name>
						<Result>crPassed</Result>
					</Check>
					<Check ID="893424">
						<CheckNo>7</CheckNo>
						<CheckType>mvrSafety</CheckType>
						<Name>Modelling&#32;Error&#32;check</Name>
						<Result>crPassed</Result>
					</Check>
					<Check ID="893425">
						<CheckNo>8</CheckNo>
						<CheckType>mvrDeadlock</CheckType>
						<Name>Deadlock&#32;check</Name>
						<Result>crPassed</Result>
					</Check>
					<Check ID="893426">
						<CheckNo>9</CheckNo>
						<CheckType>mvrRefinement</CheckType>
						<Name>Interface&#32;Compliance&#32;check</Name>
						<Result>crPassed</Result>
					</Check>
					<Check ID="893427">
						<CheckNo>10</CheckNo>
						<CheckType>mvrLivelock</CheckType>
						<Name>Relaxed&#32;Livelock&#32;check</Name>
						<Result>crPassed</Result>
					</Check>
					<Check ID="893428">
						<CheckNo>11</CheckNo>
						<CheckType>mvrDataVariables</CheckType>
						<Name>Data&#32;Variable&#32;check</Name>
						<Result>crPassed</Result>
					</Check>
				</Checks>
				<Fingerprints>
					<Fingerprint ID="893429">
						<Fingerprint>2FE38396</Fingerprint>
					</Fingerprint>
					<Fingerprint ID="893430">
						<Fingerprint>DBBAA08B</Fingerprint>
						<RelativePath>OutParam.im</RelativePath>
					</Fingerprint>
					<Fingerprint ID="893431">
						<Fingerprint>8266FF9F</Fingerprint>
						<RelativePath>MultiStepOutParam.im</RelativePath>
					</Fingerprint>
				</Fingerprints>
			</VerificationStatus>
		</VerificationStatus>
	</DesignModel>
</asd>
