<?xml version="1.0"?>
<asd OmVersion="10.10.0" BackwardOmVersion="10.10.0" Serializer="2" >
	<DesignModel ID="893071">
		<CodeGenerationLanguage>cpp</CodeGenerationLanguage>
		<CodeGenerationVersion>9.2.9</CodeGenerationVersion>
		<DateCreated>20151021T162910</DateCreated>
		<DateModified>20151120T093504</DateModified>
		<Description>Basis&#32;for&#32;testing&#32;parameter&#32;passing.</Description>
		<Guid>ADA478BDA88B485AB5FA8EE48A1E37D0</Guid>
		<ModelSignature>BASE64_Z9DCZeOYCtOjWDgHmKnzIuJtHqn0ssP33e3tk3cjqi2xrzCZHNUzlj58Q7Jar01NQt4IYyrtgpgKR+pKgeyxvv+eF1ZaZH/kejRI6i6GNJB5zRLjxzNxr+84H/cvYMXFRY5DWIU5brnPijWfCz0T8uHjoXy/otBUXVpUCte5Ji5u2NlWEpNiUfeQ7KiU6Zl34I4HdFnp3PYcJFvxWzVIS71cDZ+B6wfCKYf7htdH9XAIVPOr6ImA27ZHVYDHK0U5K9sW/oaYfVuIkDloQMwx/xY0C/5avJa3T8aXCtZoaTYMyNM9SKnmHr+VjqtPkZ4FcVw/82Sjhv3LbNGSMzZAig==</ModelSignature>
		<Name>OutParam</Name>
		<ToolVersion>ASD:Suite&#32;ModelBuilder&#32;9.2.7(52388)</ToolVersion>
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
			<DataVariable ID="893487">
				<AutoInvOption>ainvEndOfActSeq</AutoInvOption>
				<Guid>FCB8D63DD9D14BABB7EDFB9834018C1C</Guid>
				<Name>local_nr</Name>
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
									<CallEvent ID="893446">
										<Guid>5DE985E2D7C548EDA776671921C1490B</Guid>
										<Name>e_out_sync_async</Name>
										<Parameters>
											<SimpleParameter ID="893447">
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
									<CallEvent ID="893448">
										<Guid>A789C6AAC8E34507822CB58DC63FD007</Guid>
										<Name>e_inout_sync_async</Name>
										<Parameters>
											<SimpleParameter ID="893449">
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
									<CallEvent ID="894490">
										<Guid>01967BFC1A31499897DCAC36D700B6B5</Guid>
										<Name>enable_sub_machines</Name>
									</CallEvent>
									<CallEvent ID="894491">
										<Guid>47FF284BF38E43A3B749AEAC16D21CAC</Guid>
										<Name>disable_sub_machines</Name>
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
					<StateVariable ID="893488">
						<Guid>AC07C6FA74EA4AF292D640D3F11A0BFE</Guid>
						<InitialValue>false</InitialValue>
						<Name>use_sub_machine</Name>
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
										<Guard>not&#32;use_sub_machine</Guard>
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
									<RuleCase ID="893489">
										<Guard>use_sub_machine</Guard>
										<Row>5</Row>
										<StateUpdate>pending_reply&#32;=&#32;true</StateUpdate>
										<NextState>893490</NextState>
										<Actions>
											<Action ID="893491">
												<Event>893492</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893493">
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
										<Guard>not&#32;use_sub_machine</Guard>
										<Row>6</Row>
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
									<RuleCase ID="893494">
										<Guard>use_sub_machine</Guard>
										<Row>7</Row>
										<NextState>893490</NextState>
										<Actions>
											<Action ID="893495">
												<Event>893496</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893497">
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
										<Guard>not&#32;use_sub_machine</Guard>
										<Row>8</Row>
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
									<RuleCase ID="893498">
										<Guard>use_sub_machine</Guard>
										<Row>9</Row>
										<NextState>893490</NextState>
										<Actions>
											<Action ID="893499">
												<Event>893500</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893501">
												<Value>&lt;&lt;nr</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893450">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="893451">
										<Comment>Reply&#32;at&#32;end&#32;of&#32;transaction</Comment>
										<Guard>not&#32;use_sub_machine</Guard>
										<Row>10</Row>
										<StateUpdate>pending_reply&#32;=&#32;true;&#10;synchronous&#32;=&#32;false;&#10;synchronous_cb&#32;=&#32;true</StateUpdate>
										<NextState>893182</NextState>
										<Actions>
											<Action ID="893452">
												<Event>893184</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893453">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893454">
												<Value>&lt;&lt;nr</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
									<RuleCase ID="893502">
										<Guard>use_sub_machine</Guard>
										<Row>11</Row>
										<NextState>893490</NextState>
										<Actions>
											<Action ID="893503">
												<Event>893504</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893505">
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
										<Guard>not&#32;use_sub_machine</Guard>
										<Row>12</Row>
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
									<RuleCase ID="894492">
										<Guard>use_sub_machine</Guard>
										<Row>13</Row>
										<StateUpdate>pending_reply&#32;=&#32;true</StateUpdate>
										<NextState>893490</NextState>
										<Actions>
											<Action ID="894493">
												<Event>893492</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894644">
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
										<Guard>not&#32;use_sub_machine</Guard>
										<Row>14</Row>
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
									<RuleCase ID="894495">
										<Guard>use_sub_machine</Guard>
										<Row>15</Row>
										<NextState>893490</NextState>
										<Actions>
											<Action ID="894496">
												<Event>893496</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894645">
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
										<Guard>not&#32;use_sub_machine</Guard>
										<Row>16</Row>
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
									<RuleCase ID="894498">
										<Guard>use_sub_machine</Guard>
										<Row>17</Row>
										<NextState>893490</NextState>
										<Actions>
											<Action ID="894499">
												<Event>893500</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894646">
												<Value>&gt;&lt;nr</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893455">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="893456">
										<Comment>Reply&#32;at&#32;end&#32;of&#32;transaction</Comment>
										<Guard>not&#32;use_sub_machine</Guard>
										<Row>18</Row>
										<StateUpdate>pending_reply&#32;=&#32;true;&#10;synchronous&#32;=&#32;false;&#10;synchronous_cb&#32;=&#32;true</StateUpdate>
										<NextState>893182</NextState>
										<Actions>
											<Action ID="893457">
												<Event>893184</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893458">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893459">
												<Value>&gt;&lt;nr</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
									<RuleCase ID="894501">
										<Guard>use_sub_machine</Guard>
										<Row>19</Row>
										<NextState>893490</NextState>
										<Actions>
											<Action ID="894502">
												<Event>893504</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894647">
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
										<Guard>not&#32;use_sub_machine</Guard>
										<Row>20</Row>
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
									<RuleCase ID="894504">
										<Guard>use_sub_machine</Guard>
										<Row>21</Row>
										<StateUpdate>pending_reply&#32;=&#32;false</StateUpdate>
										<NextState>893490</NextState>
										<Actions>
											<Action ID="894505">
												<Event>893095</Event>
											</Action>
											<Action ID="894506">
												<Event>893492</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894507">
												<Value>&lt;&lt;nr</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894508">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894509">
										<Row>22</Row>
										<StateUpdate>use_sub_machine&#32;=&#32;true</StateUpdate>
										<NextState>893097</NextState>
										<Actions>
											<Action ID="894510">
												<Event>893095</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894511">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894512">
										<Row>23</Row>
										<StateUpdate>use_sub_machine&#32;=&#32;false</StateUpdate>
										<NextState>893097</NextState>
										<Actions>
											<Action ID="894513">
												<Event>893095</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893506">
								<Event>893507</Event>
								<RuleCases>
									<RuleCase ID="893508">
										<Row>24</Row>
										<Actions>
											<Action ID="893509">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893510">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893511">
								<Event>893512</Event>
								<RuleCases>
									<RuleCase ID="893513">
										<Row>25</Row>
										<Actions>
											<Action ID="893514">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893515">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893516">
								<Event>893517</Event>
								<RuleCases>
									<RuleCase ID="893518">
										<Row>26</Row>
										<Actions>
											<Action ID="893519">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893520">
												<Value>amount</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893521">
								<Event>893522</Event>
								<RuleCases>
									<RuleCase ID="893523">
										<Row>27</Row>
										<Actions>
											<Action ID="893524">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893525">
												<Value>amount</Value>
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
										<Row>28</Row>
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
										<Row>29</Row>
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
							<Rule ID="893526">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="893529">
										<Row>30</Row>
										<Actions>
											<Action ID="893530">
												<Event>893076</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="893490">
						<Guid>7EBA27DBB82A4649B891464FA69D2BBC</Guid>
						<Name>WaitSubMachineReturn</Name>
						<Rules>
							<Rule ID="893531">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="893532">
										<Row>56</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893533">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="893534">
										<Row>57</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893535">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="893536">
										<Row>58</Row>
										<Actions>
											<Action ID="893537">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893538">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893539">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="893540">
										<Row>59</Row>
										<Actions>
											<Action ID="893541">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893542">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893543">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="893544">
										<Row>60</Row>
										<Actions>
											<Action ID="893545">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893546">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893547">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="893548">
										<Row>61</Row>
										<Actions>
											<Action ID="893549">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893550">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893551">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="893552">
										<Row>62</Row>
										<Actions>
											<Action ID="893553">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893554">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893555">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="893556">
										<Row>63</Row>
										<Actions>
											<Action ID="893557">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893558">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893559">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="893560">
										<Row>64</Row>
										<Actions>
											<Action ID="893561">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893562">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893563">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="893564">
										<Row>65</Row>
										<Actions>
											<Action ID="893565">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893566">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893567">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="893568">
										<Row>66</Row>
										<Actions>
											<Action ID="893569">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893570">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894514">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894515">
										<Row>67</Row>
										<Actions>
											<Action ID="894516">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894517">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894518">
										<Row>68</Row>
										<Actions>
											<Action ID="894519">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893571">
								<Event>893507</Event>
								<RuleCases>
									<RuleCase ID="893572">
										<Row>69</Row>
										<NextState>893097</NextState>
										<Actions>
											<Action ID="893573">
												<Event>893095</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893574">
												<Value>&gt;&gt;nr</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893575">
								<Event>893512</Event>
								<RuleCases>
									<RuleCase ID="893576">
										<Row>70</Row>
										<NextState>893097</NextState>
										<Actions>
											<Action ID="893577">
												<Event>893095</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893578">
												<Value>&gt;&gt;nr</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893579">
								<Event>893517</Event>
								<RuleCases>
									<RuleCase ID="893580">
										<Row>71</Row>
										<NextState>893097</NextState>
										<Actions>
											<Action ID="893581">
												<Event>893095</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893582">
												<Value>&gt;&gt;nr</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893583">
								<Event>893522</Event>
								<RuleCases>
									<RuleCase ID="893584">
										<Guard>pending_reply</Guard>
										<Row>72</Row>
										<NextState>893097</NextState>
										<Actions>
											<Action ID="893585">
												<Event>893095</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893586">
												<Value>&gt;&gt;nr</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
									<RuleCase ID="894520">
										<Guard>otherwise</Guard>
										<Row>73</Row>
										<NextState>893097</NextState>
										<Actions>
											<Action ID="894521">
												<Event>893075</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894522">
												<Value>amount</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893587">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893588">
										<Row>74</Row>
										<Actions>
											<Action ID="893589">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893590">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893591">
										<Row>75</Row>
										<Actions>
											<Action ID="893592">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893593">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893594">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="893595">
										<Row>76</Row>
										<Actions>
											<Action ID="893596">
												<Event>893077</Event>
											</Action>
										</Actions>
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
										<Row>32</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893217">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="893218">
										<Row>33</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893219">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="893220">
										<Row>34</Row>
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
										<Row>35</Row>
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
										<Row>36</Row>
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
							<Rule ID="893460">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="893461">
										<Row>37</Row>
										<Actions>
											<Action ID="893462">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893463">
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
										<Row>38</Row>
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
										<Row>39</Row>
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
										<Row>40</Row>
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
							<Rule ID="893464">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="893465">
										<Row>41</Row>
										<Actions>
											<Action ID="893466">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893467">
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
										<Row>42</Row>
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
							<Rule ID="894523">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894524">
										<Row>43</Row>
										<Actions>
											<Action ID="894525">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894526">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894527">
										<Row>44</Row>
										<Actions>
											<Action ID="894528">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893597">
								<Event>893507</Event>
								<RuleCases>
									<RuleCase ID="893598">
										<Row>45</Row>
										<Actions>
											<Action ID="893599">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893600">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893601">
								<Event>893512</Event>
								<RuleCases>
									<RuleCase ID="893602">
										<Row>46</Row>
										<Actions>
											<Action ID="893603">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893604">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893605">
								<Event>893517</Event>
								<RuleCases>
									<RuleCase ID="893606">
										<Row>47</Row>
										<Actions>
											<Action ID="893607">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893608">
												<Value>amount</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893609">
								<Event>893522</Event>
								<RuleCases>
									<RuleCase ID="893610">
										<Row>48</Row>
										<Actions>
											<Action ID="893611">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893612">
												<Value>amount</Value>
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
										<Row>49</Row>
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
										<Row>50</Row>
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
									<RuleCase ID="893482">
										<Comment>Perform&#32;GetData_SyncOutResult()&#32;on&#32;tau-triggered&#32;out&#32;event</Comment>
										<Guard>(not&#32;synchronous)&#32;and&#32;synchronous_cb</Guard>
										<Row>51</Row>
										<NextState>893613</NextState>
										<Actions>
											<Action ID="893614">
												<Event>893615</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893616">
														<ServiceReference>893528</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
									<RuleCase ID="893246">
										<Guard>otherwise</Guard>
										<Row>52</Row>
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
										<Row>53</Row>
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
							<Rule ID="893617">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="893618">
										<Row>54</Row>
										<Actions>
											<Action ID="893619">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="893613">
						<Guid>8AD33E2007894695A377E3DC0DD7A203</Guid>
						<Name>WaitReflection</Name>
						<Rules>
							<Rule ID="893620">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="893621">
										<Row>122</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893622">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="893623">
										<Row>123</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893624">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="893625">
										<Row>124</Row>
										<Actions>
											<Action ID="893626">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893627">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893628">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="893629">
										<Row>125</Row>
										<Actions>
											<Action ID="893630">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893631">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893632">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="893633">
										<Row>126</Row>
										<Actions>
											<Action ID="893634">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893635">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893636">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="893637">
										<Row>127</Row>
										<Actions>
											<Action ID="893638">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893639">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893640">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="893641">
										<Row>128</Row>
										<Actions>
											<Action ID="893642">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893643">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893644">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="893645">
										<Row>129</Row>
										<Actions>
											<Action ID="893646">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893647">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893648">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="893649">
										<Row>130</Row>
										<Actions>
											<Action ID="893650">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893651">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893652">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="893653">
										<Row>131</Row>
										<Actions>
											<Action ID="893654">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893655">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893656">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="893657">
										<Row>132</Row>
										<Actions>
											<Action ID="893658">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893659">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894529">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894530">
										<Row>133</Row>
										<Actions>
											<Action ID="894531">
												<Event>893076</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894532">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894533">
										<Row>134</Row>
										<Actions>
											<Action ID="894534">
												<Event>893076</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893660">
								<Event>893507</Event>
								<RuleCases>
									<RuleCase ID="893661">
										<Row>135</Row>
										<Actions>
											<Action ID="893662">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893663">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893664">
								<Event>893512</Event>
								<RuleCases>
									<RuleCase ID="893665">
										<Row>136</Row>
										<Actions>
											<Action ID="893666">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893667">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893668">
								<Event>893517</Event>
								<RuleCases>
									<RuleCase ID="893669">
										<Row>137</Row>
										<Actions>
											<Action ID="893670">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893671">
												<Value>amount</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893672">
								<Event>893522</Event>
								<RuleCases>
									<RuleCase ID="893673">
										<Row>138</Row>
										<Actions>
											<Action ID="893674">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893675">
												<Value>amount</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893676">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893677">
										<Row>139</Row>
										<Actions>
											<Action ID="893678">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893679">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893680">
										<Row>140</Row>
										<Actions>
											<Action ID="893681">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893682">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893683">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="893684">
										<Guard>(not&#32;synchronous)&#32;and&#32;synchronous_cb</Guard>
										<Row>141</Row>
										<NextState>893247</NextState>
										<Actions>
											<Action ID="893685">
												<Event>893361</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893686">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
									<RuleCase ID="893687">
										<Guard>otherwise</Guard>
										<Row>142</Row>
										<Actions>
											<Action ID="893688">
												<Event>893076</Event>
											</Action>
										</Actions>
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
										<Row>100</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893257">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="893258">
										<Row>101</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893259">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="893260">
										<Row>102</Row>
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
										<Row>103</Row>
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
										<Row>104</Row>
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
							<Rule ID="893468">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="893469">
										<Row>105</Row>
										<Actions>
											<Action ID="893483">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893484">
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
										<Row>106</Row>
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
										<Row>107</Row>
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
										<Row>108</Row>
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
							<Rule ID="893471">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="893472">
										<Row>109</Row>
										<Actions>
											<Action ID="893485">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893486">
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
										<Row>110</Row>
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
							<Rule ID="894535">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894536">
										<Row>111</Row>
										<Actions>
											<Action ID="894537">
												<Event>893076</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894538">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894539">
										<Row>112</Row>
										<Actions>
											<Action ID="894540">
												<Event>893076</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893689">
								<Event>893507</Event>
								<RuleCases>
									<RuleCase ID="893690">
										<Row>113</Row>
										<Actions>
											<Action ID="893691">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893692">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893693">
								<Event>893512</Event>
								<RuleCases>
									<RuleCase ID="893694">
										<Row>114</Row>
										<Actions>
											<Action ID="893695">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893696">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893697">
								<Event>893517</Event>
								<RuleCases>
									<RuleCase ID="893698">
										<Row>115</Row>
										<Actions>
											<Action ID="893699">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893700">
												<Value>amount</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893701">
								<Event>893522</Event>
								<RuleCases>
									<RuleCase ID="893702">
										<Row>116</Row>
										<Actions>
											<Action ID="893703">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893704">
												<Value>amount</Value>
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
										<Row>117</Row>
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
										<Guard>otherwise</Guard>
										<Row>118</Row>
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
									<RuleCase ID="893705">
										<Guard>false&#32;and&#32;(not&#32;synchronous)&#32;and&#32;synchronous_cb</Guard>
										<Row>119</Row>
										<Actions>
											<Action ID="893706">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893707">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893708">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="893709">
										<Row>120</Row>
										<Actions>
											<Action ID="893710">
												<Event>893076</Event>
											</Action>
										</Actions>
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
										<Row>78</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893291">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="893292">
										<Row>79</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893293">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="893294">
										<Row>80</Row>
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
										<Row>81</Row>
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
										<Row>82</Row>
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
							<Rule ID="893474">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="893475">
										<Row>83</Row>
										<Actions>
											<Action ID="893476">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893477">
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
										<Row>84</Row>
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
										<Row>85</Row>
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
										<Row>86</Row>
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
							<Rule ID="893478">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="893479">
										<Row>87</Row>
										<Actions>
											<Action ID="893480">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893481">
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
										<Row>88</Row>
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
							<Rule ID="894541">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894542">
										<Row>89</Row>
										<Actions>
											<Action ID="894543">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894544">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894545">
										<Row>90</Row>
										<Actions>
											<Action ID="894546">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893711">
								<Event>893507</Event>
								<RuleCases>
									<RuleCase ID="893712">
										<Row>91</Row>
										<Actions>
											<Action ID="893713">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893714">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893715">
								<Event>893512</Event>
								<RuleCases>
									<RuleCase ID="893716">
										<Row>92</Row>
										<Actions>
											<Action ID="893717">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893718">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893719">
								<Event>893517</Event>
								<RuleCases>
									<RuleCase ID="893720">
										<Row>93</Row>
										<Actions>
											<Action ID="893721">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893722">
												<Value>amount</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893723">
								<Event>893522</Event>
								<RuleCases>
									<RuleCase ID="893724">
										<Row>94</Row>
										<Actions>
											<Action ID="893725">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893726">
												<Value>amount</Value>
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
										<Row>95</Row>
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
										<Row>96</Row>
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
										<Row>97</Row>
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
							<Rule ID="893727">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="893728">
										<Row>98</Row>
										<Actions>
											<Action ID="893729">
												<Event>893077</Event>
											</Action>
										</Actions>
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
			<ServiceReference ID="893528">
				<Construction>Reflector</Construction>
				<Guid>DB6A9859830648E69ECEBF399CC5EB6C</Guid>
				<Name>reflector</Name>
				<Dependency>893730</Dependency>
			</ServiceReference>
		</ServiceReferences>
		<SubMachines>
			<SubMachine ID="893731">
				<Guid>3DF4EA28DE6645F69B23C888B8A74B48</Guid>
				<Name>TauFlushSyncOut</Name>
				<States>
					<State ID="893732">
						<Guid>0AEA603561344E9196D65CA204E71055</Guid>
						<Name>Idle</Name>
						<Rules>
							<Rule ID="893733">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="893734">
										<Row>2</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893735">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="893736">
										<Row>3</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893737">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="893738">
										<Row>4</Row>
										<Actions>
											<Action ID="893739">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893740">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893741">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="893742">
										<Row>5</Row>
										<Actions>
											<Action ID="893743">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893744">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893745">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="893746">
										<Row>6</Row>
										<Actions>
											<Action ID="893747">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893748">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893749">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="893750">
										<Row>7</Row>
										<Actions>
											<Action ID="893751">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893752">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893753">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="893754">
										<Row>8</Row>
										<Actions>
											<Action ID="893755">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893756">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893757">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="893758">
										<Row>9</Row>
										<Actions>
											<Action ID="893759">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893760">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893761">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="893762">
										<Row>10</Row>
										<Actions>
											<Action ID="893763">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893764">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893765">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="893766">
										<Row>11</Row>
										<Actions>
											<Action ID="893767">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893768">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893769">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="893770">
										<Row>12</Row>
										<Actions>
											<Action ID="893771">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893772">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894547">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894548">
										<Row>13</Row>
										<Actions>
											<Action ID="894549">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894550">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894551">
										<Row>14</Row>
										<Actions>
											<Action ID="894552">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893773">
								<Event>893504</Event>
								<RuleCases>
									<RuleCase ID="893774">
										<Row>15</Row>
										<NextState>893775</NextState>
										<Actions>
											<Action ID="893776">
												<Event>893184</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893777">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893778">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893779">
										<Row>16</Row>
										<Actions>
											<Action ID="893780">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893781">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893782">
										<Row>17</Row>
										<Actions>
											<Action ID="893783">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893784">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893785">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="893786">
										<Row>18</Row>
										<Actions>
											<Action ID="893787">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="893775">
						<Guid>0C0B4DF2150247BC867A1C1F6AE5E601</Guid>
						<Name>WaitInit</Name>
						<Rules>
							<Rule ID="893788">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="893789">
										<Row>20</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893790">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="893791">
										<Row>21</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893792">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="893793">
										<Row>22</Row>
										<Actions>
											<Action ID="893794">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893795">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893796">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="893797">
										<Row>23</Row>
										<Actions>
											<Action ID="893798">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893799">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893800">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="893801">
										<Row>24</Row>
										<Actions>
											<Action ID="893802">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893803">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893804">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="893805">
										<Row>25</Row>
										<Actions>
											<Action ID="893806">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893807">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893808">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="893809">
										<Row>26</Row>
										<Actions>
											<Action ID="893810">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893811">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893812">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="893813">
										<Row>27</Row>
										<Actions>
											<Action ID="893814">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893815">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893816">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="893817">
										<Row>28</Row>
										<Actions>
											<Action ID="893818">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893819">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893820">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="893821">
										<Row>29</Row>
										<Actions>
											<Action ID="893822">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893823">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893824">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="893825">
										<Row>30</Row>
										<Actions>
											<Action ID="893826">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893827">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894553">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894554">
										<Row>31</Row>
										<Actions>
											<Action ID="894555">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894556">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894557">
										<Row>32</Row>
										<Actions>
											<Action ID="894558">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893828">
								<Event>893504</Event>
								<RuleCases>
									<RuleCase ID="893829">
										<Row>33</Row>
										<Actions>
											<Action ID="893830">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893831">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893832">
										<Comment>Perform&#32;GetData_SyncOutResult()&#32;on&#32;tau-triggered&#32;out&#32;event</Comment>
										<Row>34</Row>
										<NextState>893833</NextState>
										<Actions>
											<Action ID="893834">
												<Event>893615</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893835">
														<ServiceReference>893528</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893836">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893837">
										<Row>35</Row>
										<Actions>
											<Action ID="893838">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893839">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893840">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="893841">
										<Row>36</Row>
										<Actions>
											<Action ID="893842">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="893833">
						<Guid>59CEAD9C34DD4973B894E50B0AD6D554</Guid>
						<Name>WaitReflection</Name>
						<Rules>
							<Rule ID="893843">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="893844">
										<Row>38</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893845">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="893846">
										<Row>39</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893847">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="893848">
										<Row>40</Row>
										<Actions>
											<Action ID="893849">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893850">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893851">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="893852">
										<Row>41</Row>
										<Actions>
											<Action ID="893853">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893854">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893855">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="893856">
										<Row>42</Row>
										<Actions>
											<Action ID="893857">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893858">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893859">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="893860">
										<Row>43</Row>
										<Actions>
											<Action ID="893861">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893862">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893863">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="893864">
										<Row>44</Row>
										<Actions>
											<Action ID="893865">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893866">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893867">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="893868">
										<Row>45</Row>
										<Actions>
											<Action ID="893869">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893870">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893871">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="893872">
										<Row>46</Row>
										<Actions>
											<Action ID="893873">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893874">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893875">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="893876">
										<Row>47</Row>
										<Actions>
											<Action ID="893877">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893878">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893879">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="893880">
										<Row>48</Row>
										<Actions>
											<Action ID="893881">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893882">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894559">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894560">
										<Row>49</Row>
										<Actions>
											<Action ID="894561">
												<Event>893076</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894562">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894563">
										<Row>50</Row>
										<Actions>
											<Action ID="894564">
												<Event>893076</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893883">
								<Event>893504</Event>
								<RuleCases>
									<RuleCase ID="893884">
										<Row>51</Row>
										<Actions>
											<Action ID="893885">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893886">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893887">
										<Row>52</Row>
										<Actions>
											<Action ID="893888">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893889">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893890">
										<Row>53</Row>
										<Actions>
											<Action ID="893891">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893892">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893893">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="893894">
										<Row>54</Row>
										<NextState>893895</NextState>
										<Actions>
											<Action ID="893896">
												<Event>893361</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893897">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="893895">
						<Guid>46AFADC70D18453C90166DEDA50CA6CA</Guid>
						<Name>WaitReceive</Name>
						<Rules>
							<Rule ID="893898">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="893899">
										<Row>56</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893900">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="893901">
										<Row>57</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893902">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="893903">
										<Row>58</Row>
										<Actions>
											<Action ID="893904">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893905">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893906">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="893907">
										<Row>59</Row>
										<Actions>
											<Action ID="893908">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893909">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893910">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="893911">
										<Row>60</Row>
										<Actions>
											<Action ID="893912">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893913">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893914">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="893915">
										<Row>61</Row>
										<Actions>
											<Action ID="893916">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893917">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893918">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="893919">
										<Row>62</Row>
										<Actions>
											<Action ID="893920">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893921">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893922">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="893923">
										<Row>63</Row>
										<Actions>
											<Action ID="893924">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893925">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893926">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="893927">
										<Row>64</Row>
										<Actions>
											<Action ID="893928">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893929">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893930">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="893931">
										<Row>65</Row>
										<Actions>
											<Action ID="893932">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893933">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893934">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="893935">
										<Row>66</Row>
										<Actions>
											<Action ID="893936">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893937">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894565">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894566">
										<Row>67</Row>
										<Actions>
											<Action ID="894567">
												<Event>893076</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894568">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894569">
										<Row>68</Row>
										<Actions>
											<Action ID="894570">
												<Event>893076</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893938">
								<Event>893504</Event>
								<RuleCases>
									<RuleCase ID="893939">
										<Row>69</Row>
										<Actions>
											<Action ID="893940">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893941">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893942">
										<Row>70</Row>
										<Actions>
											<Action ID="893943">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893944">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="893945">
										<Row>71</Row>
										<NextState>893732</NextState>
										<Actions>
											<Action ID="893946">
												<Event>893285</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="893947">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
											<Action ID="893948">
												<Event>893507</Event>
												<Arguments>
													<SimpleArgument ID="893949">
														<Value>getal</Value>
													</SimpleArgument>
												</Arguments>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893950">
												<Value>getal</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893951">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="893952">
										<Row>72</Row>
										<Actions>
											<Action ID="893953">
												<Event>893076</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
				</States>
				<TransferInterface>
					<TransferInterface ID="893954">
						<Guid>8560CEF979C84B8BA563464270BFCD8A</Guid>
						<Name>TransferTauFlushSyncOut</Name>
						<Events>
							<CallEvent ID="893504">
								<Guid>D76B8241042C4B0E97B8772059DDBE90</Guid>
								<Name>produce</Name>
								<ReplyType>rtValued</ReplyType>
							</CallEvent>
						</Events>
						<ReplyEvents>
							<ReplyEvent ID="893507">
								<Guid>CABA6150E8E642A281075F135667F7D0</Guid>
								<Name>consume</Name>
								<Parameters>
									<SimpleParameter ID="893955">
										<Name>amount</Name>
										<Type>int</Type>
									</SimpleParameter>
								</Parameters>
							</ReplyEvent>
						</ReplyEvents>
					</TransferInterface>
				</TransferInterface>
			</SubMachine>
			<SubMachine ID="893956">
				<Guid>BA11FE041941406E9CEDD63CA942FE9F</Guid>
				<Name>TauRelease</Name>
				<States>
					<State ID="893957">
						<Guid>267993E102934A8F928DA5F7186F0E5F</Guid>
						<Name>Idle</Name>
						<Rules>
							<Rule ID="893958">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="893959">
										<Row>2</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893960">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="893961">
										<Row>3</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893962">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="893963">
										<Row>4</Row>
										<Actions>
											<Action ID="893964">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893965">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893966">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="893967">
										<Row>5</Row>
										<Actions>
											<Action ID="893968">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893969">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893970">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="893971">
										<Row>6</Row>
										<Actions>
											<Action ID="893972">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893973">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893974">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="893975">
										<Row>7</Row>
										<Actions>
											<Action ID="893976">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893977">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893978">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="893979">
										<Row>8</Row>
										<Actions>
											<Action ID="893980">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893981">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893982">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="893983">
										<Row>9</Row>
										<Actions>
											<Action ID="893984">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893985">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893986">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="893987">
										<Row>10</Row>
										<Actions>
											<Action ID="893988">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893989">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893990">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="893991">
										<Row>11</Row>
										<Actions>
											<Action ID="893992">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893993">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893994">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="893995">
										<Row>12</Row>
										<Actions>
											<Action ID="893996">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="893997">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894571">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894572">
										<Row>13</Row>
										<Actions>
											<Action ID="894573">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894574">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894575">
										<Row>14</Row>
										<Actions>
											<Action ID="894576">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="893998">
								<Event>893500</Event>
								<RuleCases>
									<RuleCase ID="893999">
										<Row>15</Row>
										<NextState>894000</NextState>
										<Actions>
											<Action ID="894001">
												<Event>893184</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="894002">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894003">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894004">
										<Row>16</Row>
										<Actions>
											<Action ID="894005">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894006">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894007">
										<Row>17</Row>
										<Actions>
											<Action ID="894008">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894009">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894010">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="894011">
										<Row>18</Row>
										<Actions>
											<Action ID="894012">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="894000">
						<Guid>591222C52176426C859A603277A7D73C</Guid>
						<Name>WaitInit</Name>
						<Rules>
							<Rule ID="894013">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="894014">
										<Row>20</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894015">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="894016">
										<Row>21</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894017">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="894018">
										<Row>22</Row>
										<Actions>
											<Action ID="894019">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894020">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894021">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="894022">
										<Row>23</Row>
										<Actions>
											<Action ID="894023">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894024">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894025">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="894026">
										<Row>24</Row>
										<Actions>
											<Action ID="894027">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894028">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894029">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="894030">
										<Row>25</Row>
										<Actions>
											<Action ID="894031">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894032">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894033">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="894034">
										<Row>26</Row>
										<Actions>
											<Action ID="894035">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894036">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894037">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="894038">
										<Row>27</Row>
										<Actions>
											<Action ID="894039">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894040">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894041">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="894042">
										<Row>28</Row>
										<Actions>
											<Action ID="894043">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894044">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894045">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="894046">
										<Row>29</Row>
										<Actions>
											<Action ID="894047">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894048">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894049">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="894050">
										<Row>30</Row>
										<Actions>
											<Action ID="894051">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894052">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894577">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894578">
										<Row>31</Row>
										<Actions>
											<Action ID="894579">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894580">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894581">
										<Row>32</Row>
										<Actions>
											<Action ID="894582">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894053">
								<Event>893500</Event>
								<RuleCases>
									<RuleCase ID="894054">
										<Row>33</Row>
										<Actions>
											<Action ID="894055">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894056">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894057">
										<Row>34</Row>
										<NextState>894058</NextState>
										<Actions>
											<Action ID="894059">
												<Event>893249</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="894060">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894061">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894062">
										<Row>35</Row>
										<Actions>
											<Action ID="894063">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894064">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894065">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="894066">
										<Row>36</Row>
										<Actions>
											<Action ID="894067">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="894058">
						<Guid>26A5839F07D14AAF93B1A84786F849EC</Guid>
						<Name>WaitData</Name>
						<Rules>
							<Rule ID="894068">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="894069">
										<Row>38</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894070">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="894071">
										<Row>39</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894072">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="894073">
										<Row>40</Row>
										<Actions>
											<Action ID="894074">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894075">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894076">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="894077">
										<Row>41</Row>
										<Actions>
											<Action ID="894078">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894079">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894080">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="894081">
										<Row>42</Row>
										<Actions>
											<Action ID="894082">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894083">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894084">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="894085">
										<Row>43</Row>
										<Actions>
											<Action ID="894086">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894087">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894088">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="894089">
										<Row>44</Row>
										<Actions>
											<Action ID="894090">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894091">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894092">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="894093">
										<Row>45</Row>
										<Actions>
											<Action ID="894094">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894095">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894096">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="894097">
										<Row>46</Row>
										<Actions>
											<Action ID="894098">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894099">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894100">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="894101">
										<Row>47</Row>
										<Actions>
											<Action ID="894102">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894103">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894104">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="894105">
										<Row>48</Row>
										<Actions>
											<Action ID="894106">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894107">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894583">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894584">
										<Row>49</Row>
										<Actions>
											<Action ID="894585">
												<Event>893076</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894586">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894587">
										<Row>50</Row>
										<Actions>
											<Action ID="894588">
												<Event>893076</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894108">
								<Event>893500</Event>
								<RuleCases>
									<RuleCase ID="894109">
										<Row>51</Row>
										<Actions>
											<Action ID="894110">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894111">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894112">
										<Row>52</Row>
										<Actions>
											<Action ID="894113">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894114">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894115">
										<Row>53</Row>
										<NextState>893957</NextState>
										<Actions>
											<Action ID="894116">
												<Event>893285</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="894117">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
											<Action ID="894118">
												<Event>893512</Event>
												<Arguments>
													<SimpleArgument ID="894119">
														<Value>getal</Value>
													</SimpleArgument>
												</Arguments>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894120">
												<Value>getal</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894121">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="894122">
										<Row>54</Row>
										<Actions>
											<Action ID="894123">
												<Event>893076</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
				</States>
				<TransferInterface>
					<TransferInterface ID="894124">
						<Guid>1B507BF94F564BC1A69341F68754D848</Guid>
						<Name>TransferTauRelease</Name>
						<Events>
							<CallEvent ID="893500">
								<Guid>9E0F0DFC6C2B472F84E384488976BFD3</Guid>
								<Name>produce</Name>
								<ReplyType>rtValued</ReplyType>
							</CallEvent>
						</Events>
						<ReplyEvents>
							<ReplyEvent ID="893512">
								<Guid>6F6B1643F9914021917FBBB12ED0219A</Guid>
								<Name>consume</Name>
								<Parameters>
									<SimpleParameter ID="894125">
										<Name>amount</Name>
										<Type>int</Type>
									</SimpleParameter>
								</Parameters>
							</ReplyEvent>
						</ReplyEvents>
					</TransferInterface>
				</TransferInterface>
			</SubMachine>
			<SubMachine ID="894126">
				<Guid>BFF3F557186843DABA000BF18F54C708</Guid>
				<Name>SynchronousOutRelease</Name>
				<States>
					<State ID="894127">
						<Guid>E94C6C3AE071404F93C425F5BD21F7F6</Guid>
						<Name>Idle</Name>
						<Rules>
							<Rule ID="894128">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="894129">
										<Row>2</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894130">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="894131">
										<Row>3</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894132">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="894133">
										<Row>4</Row>
										<Actions>
											<Action ID="894134">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894135">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894136">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="894137">
										<Row>5</Row>
										<Actions>
											<Action ID="894138">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894139">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894140">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="894141">
										<Row>6</Row>
										<Actions>
											<Action ID="894142">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894143">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894144">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="894145">
										<Row>7</Row>
										<Actions>
											<Action ID="894146">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894147">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894148">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="894149">
										<Row>8</Row>
										<Actions>
											<Action ID="894150">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894151">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894152">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="894153">
										<Row>9</Row>
										<Actions>
											<Action ID="894154">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894155">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894156">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="894157">
										<Row>10</Row>
										<Actions>
											<Action ID="894158">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894159">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894160">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="894161">
										<Row>11</Row>
										<Actions>
											<Action ID="894162">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894163">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894164">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="894165">
										<Row>12</Row>
										<Actions>
											<Action ID="894166">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894167">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894589">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894590">
										<Row>13</Row>
										<Actions>
											<Action ID="894591">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894592">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894593">
										<Row>14</Row>
										<Actions>
											<Action ID="894594">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894168">
								<Event>893496</Event>
								<RuleCases>
									<RuleCase ID="894169">
										<Row>15</Row>
										<NextState>894170</NextState>
										<Actions>
											<Action ID="894171">
												<Event>893184</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="894172">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894173">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894174">
										<Row>16</Row>
										<Actions>
											<Action ID="894175">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894176">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894177">
										<Row>17</Row>
										<Actions>
											<Action ID="894178">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894179">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894180">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="894181">
										<Row>18</Row>
										<Actions>
											<Action ID="894182">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="894170">
						<Guid>1CD3E9E4D64D4280BD487846984B2B2A</Guid>
						<Name>WaitInit</Name>
						<Rules>
							<Rule ID="894183">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="894184">
										<Row>20</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894185">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="894186">
										<Row>21</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894187">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="894188">
										<Row>22</Row>
										<Actions>
											<Action ID="894189">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894190">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894191">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="894192">
										<Row>23</Row>
										<Actions>
											<Action ID="894193">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894194">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894195">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="894196">
										<Row>24</Row>
										<Actions>
											<Action ID="894197">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894198">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894199">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="894200">
										<Row>25</Row>
										<Actions>
											<Action ID="894201">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894202">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894203">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="894204">
										<Row>26</Row>
										<Actions>
											<Action ID="894205">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894206">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894207">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="894208">
										<Row>27</Row>
										<Actions>
											<Action ID="894209">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894210">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894211">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="894212">
										<Row>28</Row>
										<Actions>
											<Action ID="894213">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894214">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894215">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="894216">
										<Row>29</Row>
										<Actions>
											<Action ID="894217">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894218">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894219">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="894220">
										<Row>30</Row>
										<Actions>
											<Action ID="894221">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894222">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894595">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894596">
										<Row>31</Row>
										<Actions>
											<Action ID="894597">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894598">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894599">
										<Row>32</Row>
										<Actions>
											<Action ID="894600">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894223">
								<Event>893496</Event>
								<RuleCases>
									<RuleCase ID="894224">
										<Row>33</Row>
										<Actions>
											<Action ID="894225">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894226">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894227">
										<Row>34</Row>
										<NextState>894228</NextState>
										<Actions>
											<Action ID="894229">
												<Event>893361</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="894230">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894231">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894232">
										<Row>35</Row>
										<Actions>
											<Action ID="894233">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894234">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894235">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="894236">
										<Row>36</Row>
										<Actions>
											<Action ID="894237">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="894228">
						<Guid>3BDBF1980876489683936A2EEAE3E31E</Guid>
						<Name>WaitData</Name>
						<Rules>
							<Rule ID="894238">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="894239">
										<Row>38</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894240">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="894241">
										<Row>39</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894242">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="894243">
										<Row>40</Row>
										<Actions>
											<Action ID="894244">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894245">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894246">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="894247">
										<Row>41</Row>
										<Actions>
											<Action ID="894248">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894249">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894250">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="894251">
										<Row>42</Row>
										<Actions>
											<Action ID="894252">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894253">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894254">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="894255">
										<Row>43</Row>
										<Actions>
											<Action ID="894256">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894257">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894258">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="894259">
										<Row>44</Row>
										<Actions>
											<Action ID="894260">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894261">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894262">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="894263">
										<Row>45</Row>
										<Actions>
											<Action ID="894264">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894265">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894266">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="894267">
										<Row>46</Row>
										<Actions>
											<Action ID="894268">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894269">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894270">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="894271">
										<Row>47</Row>
										<Actions>
											<Action ID="894272">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894273">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894274">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="894275">
										<Row>48</Row>
										<Actions>
											<Action ID="894276">
												<Event>893076</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894277">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894601">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894602">
										<Row>49</Row>
										<Actions>
											<Action ID="894603">
												<Event>893076</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894604">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894605">
										<Row>50</Row>
										<Actions>
											<Action ID="894606">
												<Event>893076</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894278">
								<Event>893496</Event>
								<RuleCases>
									<RuleCase ID="894279">
										<Row>51</Row>
										<Actions>
											<Action ID="894280">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894281">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894282">
										<Row>52</Row>
										<Actions>
											<Action ID="894283">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894284">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894285">
										<Row>53</Row>
										<NextState>894127</NextState>
										<Actions>
											<Action ID="894286">
												<Event>893285</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="894287">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
											<Action ID="894288">
												<Event>893517</Event>
												<Arguments>
													<SimpleArgument ID="894289">
														<Value>getal</Value>
													</SimpleArgument>
												</Arguments>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894290">
												<Value>getal</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894291">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="894292">
										<Row>54</Row>
										<Actions>
											<Action ID="894293">
												<Event>893076</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
				</States>
				<TransferInterface>
					<TransferInterface ID="894294">
						<Guid>E7715E479B6D45B2B74068BD24A3D789</Guid>
						<Name>TransferSynchronousOutRelease</Name>
						<Events>
							<CallEvent ID="893496">
								<Guid>0CFEFCE41F474F279A042F598A2C3D22</Guid>
								<Name>produce</Name>
								<ReplyType>rtValued</ReplyType>
							</CallEvent>
						</Events>
						<ReplyEvents>
							<ReplyEvent ID="893517">
								<Guid>BBFAF659ACAF4EB2B1DAD67809DC0103</Guid>
								<Name>consume</Name>
								<Parameters>
									<SimpleParameter ID="894295">
										<Name>amount</Name>
										<Type>int</Type>
									</SimpleParameter>
								</Parameters>
							</ReplyEvent>
						</ReplyEvents>
					</TransferInterface>
				</TransferInterface>
			</SubMachine>
			<SubMachine ID="894296">
				<Guid>F7ED85839ECD414C8881C5DC279F9051</Guid>
				<Name>SynchronousCallRelease</Name>
				<States>
					<State ID="894297">
						<Guid>6040186665604AC09684A3CEB72722AF</Guid>
						<Name>Idle</Name>
						<Rules>
							<Rule ID="894298">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="894299">
										<Row>2</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894300">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="894301">
										<Row>3</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894302">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="894303">
										<Row>4</Row>
										<Actions>
											<Action ID="894304">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894305">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894306">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="894307">
										<Row>5</Row>
										<Actions>
											<Action ID="894308">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894309">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894310">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="894311">
										<Row>6</Row>
										<Actions>
											<Action ID="894312">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894313">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894314">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="894315">
										<Row>7</Row>
										<Actions>
											<Action ID="894316">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894317">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894318">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="894319">
										<Row>8</Row>
										<Actions>
											<Action ID="894320">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894321">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894322">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="894323">
										<Row>9</Row>
										<Actions>
											<Action ID="894324">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894325">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894326">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="894327">
										<Row>10</Row>
										<Actions>
											<Action ID="894328">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894329">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894330">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="894331">
										<Row>11</Row>
										<Actions>
											<Action ID="894332">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894333">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894334">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="894335">
										<Row>12</Row>
										<Actions>
											<Action ID="894336">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894337">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894607">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894608">
										<Row>13</Row>
										<Actions>
											<Action ID="894609">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894610">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894611">
										<Row>14</Row>
										<Actions>
											<Action ID="894612">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894338">
								<Event>893492</Event>
								<RuleCases>
									<RuleCase ID="894339">
										<Row>15</Row>
										<NextState>894340</NextState>
										<Actions>
											<Action ID="894341">
												<Event>893184</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="894342">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894343">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894344">
										<Row>16</Row>
										<Actions>
											<Action ID="894345">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894346">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894347">
										<Row>17</Row>
										<Actions>
											<Action ID="894348">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894349">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894350">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="894351">
										<Row>18</Row>
										<Actions>
											<Action ID="894352">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="894340">
						<Guid>B365821A78EC45E6B4C40B17FD84841F</Guid>
						<Name>WaitInit</Name>
						<Rules>
							<Rule ID="894353">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="894354">
										<Row>20</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894355">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="894356">
										<Row>21</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894357">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="894358">
										<Row>22</Row>
										<Actions>
											<Action ID="894359">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894360">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894361">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="894362">
										<Row>23</Row>
										<Actions>
											<Action ID="894363">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894364">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894365">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="894366">
										<Row>24</Row>
										<Actions>
											<Action ID="894367">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894368">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894369">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="894370">
										<Row>25</Row>
										<Actions>
											<Action ID="894371">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894372">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894373">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="894374">
										<Row>26</Row>
										<Actions>
											<Action ID="894375">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894376">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894377">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="894378">
										<Row>27</Row>
										<Actions>
											<Action ID="894379">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894380">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894381">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="894382">
										<Row>28</Row>
										<Actions>
											<Action ID="894383">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894384">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894385">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="894386">
										<Row>29</Row>
										<Actions>
											<Action ID="894387">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894388">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894389">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="894390">
										<Row>30</Row>
										<Actions>
											<Action ID="894391">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894392">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894613">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894614">
										<Row>31</Row>
										<Actions>
											<Action ID="894615">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894616">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894617">
										<Row>32</Row>
										<Actions>
											<Action ID="894618">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894393">
								<Event>893492</Event>
								<RuleCases>
									<RuleCase ID="894394">
										<Row>33</Row>
										<Actions>
											<Action ID="894395">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894396">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894397">
										<Row>34</Row>
										<NextState>894398</NextState>
										<Actions>
											<Action ID="894399">
												<Event>893243</Event>
												<Arguments>
													<SimpleArgument ID="894400">
														<Value>&gt;&gt;local_nr</Value>
													</SimpleArgument>
												</Arguments>
												<USRExpression>
													<ServiceReferenceExpression ID="894401">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894402">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894403">
										<Row>35</Row>
										<Actions>
											<Action ID="894404">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894405">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894406">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="894407">
										<Row>36</Row>
										<Actions>
											<Action ID="894408">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="894398">
						<Guid>0AF300116C1B4BE58CC4CC364515533D</Guid>
						<Name>WaitGetData</Name>
						<Rules>
							<Rule ID="894409">
								<Event>893073</Event>
								<RuleCases>
									<RuleCase ID="894410">
										<Row>38</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894411">
								<Event>893074</Event>
								<RuleCases>
									<RuleCase ID="894412">
										<Row>39</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894413">
								<Event>893091</Event>
								<RuleCases>
									<RuleCase ID="894414">
										<Row>40</Row>
										<Actions>
											<Action ID="894415">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894416">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894417">
								<Event>893375</Event>
								<RuleCases>
									<RuleCase ID="894418">
										<Row>41</Row>
										<Actions>
											<Action ID="894419">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894420">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894421">
								<Event>893174</Event>
								<RuleCases>
									<RuleCase ID="894422">
										<Row>42</Row>
										<Actions>
											<Action ID="894423">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894424">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894425">
								<Event>893446</Event>
								<RuleCases>
									<RuleCase ID="894426">
										<Row>43</Row>
										<Actions>
											<Action ID="894427">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894428">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894429">
								<Event>893093</Event>
								<RuleCases>
									<RuleCase ID="894430">
										<Row>44</Row>
										<Actions>
											<Action ID="894431">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894432">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894433">
								<Event>893377</Event>
								<RuleCases>
									<RuleCase ID="894434">
										<Row>45</Row>
										<Actions>
											<Action ID="894435">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894436">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894437">
								<Event>893176</Event>
								<RuleCases>
									<RuleCase ID="894438">
										<Row>46</Row>
										<Actions>
											<Action ID="894439">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894440">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894441">
								<Event>893448</Event>
								<RuleCases>
									<RuleCase ID="894442">
										<Row>47</Row>
										<Actions>
											<Action ID="894443">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894444">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894445">
								<Event>893178</Event>
								<RuleCases>
									<RuleCase ID="894446">
										<Row>48</Row>
										<Actions>
											<Action ID="894447">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894448">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894619">
								<Event>894490</Event>
								<RuleCases>
									<RuleCase ID="894620">
										<Row>49</Row>
										<Actions>
											<Action ID="894621">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894622">
								<Event>894491</Event>
								<RuleCases>
									<RuleCase ID="894623">
										<Row>50</Row>
										<Actions>
											<Action ID="894624">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894449">
								<Event>893492</Event>
								<RuleCases>
									<RuleCase ID="894450">
										<Row>51</Row>
										<Actions>
											<Action ID="894451">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894452">
								<Event>893207</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894453">
										<Row>52</Row>
										<NextState>894297</NextState>
										<Actions>
											<Action ID="894454">
												<Event>893285</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="894455">
														<ServiceReference>893186</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
											<Action ID="894456">
												<Event>893522</Event>
												<Arguments>
													<SimpleArgument ID="894457">
														<Value>&lt;&lt;local_nr</Value>
													</SimpleArgument>
												</Arguments>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894458">
								<Event>893211</Event>
								<ServiceReference>893186</ServiceReference>
								<RuleCases>
									<RuleCase ID="894459">
										<Row>53</Row>
										<Actions>
											<Action ID="894460">
												<Event>893077</Event>
											</Action>
										</Actions>
										<Arguments>
											<SimpleArgument ID="894461">
												<Value>number</Value>
											</SimpleArgument>
										</Arguments>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="894462">
								<Event>893527</Event>
								<ServiceReference>893528</ServiceReference>
								<RuleCases>
									<RuleCase ID="894463">
										<Row>54</Row>
										<Actions>
											<Action ID="894464">
												<Event>893077</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
				</States>
				<TransferInterface>
					<TransferInterface ID="894465">
						<Guid>5EB368CD2E004AD3A627020B66CFB972</Guid>
						<Name>TransferSynchronousCallRelease</Name>
						<Events>
							<CallEvent ID="893492">
								<Guid>83B7CE26183D4375A83C57B4474346A1</Guid>
								<Name>produce</Name>
								<ReplyType>rtValued</ReplyType>
							</CallEvent>
						</Events>
						<ReplyEvents>
							<ReplyEvent ID="893522">
								<Guid>381B556205144D748AC35383514110B0</Guid>
								<Name>consume</Name>
								<Parameters>
									<SimpleParameter ID="894466">
										<Name>amount</Name>
										<Type>int</Type>
									</SimpleParameter>
								</Parameters>
							</ReplyEvent>
						</ReplyEvents>
					</TransferInterface>
				</TransferInterface>
			</SubMachine>
		</SubMachines>
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
			<ServiceDependency ID="893730">
				<ModelGuid>E4CCFDF9D7A84CB09770E5D4DA17B499</ModelGuid>
				<Name>Reflector</Name>
				<RelativePath>Reflector.im</RelativePath>
				<Declaration>
					<ServiceDeclaration ID="894467">
						<ApplicationInterfaces>
							<ApplicationInterface ID="894468">
								<Guid>A025BC2087674E7F976963C513285D97</Guid>
								<Name>IReflector</Name>
								<Used>1</Used>
								<Events>
									<CallEvent ID="893615">
										<Guid>A47B69DB354543BE9128F574FB31CD89</Guid>
										<Name>Ping</Name>
									</CallEvent>
								</Events>
								<ReplyEvents>
									<ReplyEvent ID="894469">
										<Guid>AE8B35E3D8814EC29177AA4DDE3C9598</Guid>
										<Name>VoidReply</Name>
									</ReplyEvent>
								</ReplyEvents>
							</ApplicationInterface>
						</ApplicationInterfaces>
						<NotificationInterfaces>
							<NotificationInterface ID="894470">
								<Guid>52FB13F8BA024C5AACEF7A2174567FBC</Guid>
								<Name>IReflectorNI</Name>
								<Used>1</Used>
								<Events>
									<NotificationEvent ID="893527">
										<Guid>B39535D7C2C54CE9B974F8836FAA7304</Guid>
										<Name>Pong</Name>
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
					<Check ID="894625">
						<CheckType>mvrSafety</CheckType>
						<Name>Modelling&#32;Error&#32;check</Name>
						<RelativePath>OutParam.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="894626">
						<CheckNo>1</CheckNo>
						<CheckType>mvrLivelock</CheckType>
						<Name>Livelock&#32;check</Name>
						<RelativePath>OutParam.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="894627">
						<CheckNo>2</CheckNo>
						<CheckType>mvrDeadlock</CheckType>
						<Name>Deadlock&#32;check</Name>
						<RelativePath>OutParam.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="894628">
						<CheckNo>3</CheckNo>
						<CheckType>mvrSafety</CheckType>
						<Name>Modelling&#32;Error&#32;check</Name>
						<RelativePath>MultiStepOutParam.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="894629">
						<CheckNo>4</CheckNo>
						<CheckType>mvrLivelock</CheckType>
						<Name>Livelock&#32;check</Name>
						<RelativePath>MultiStepOutParam.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="894630">
						<CheckNo>5</CheckNo>
						<CheckType>mvrDeadlock</CheckType>
						<Name>Deadlock&#32;check</Name>
						<RelativePath>MultiStepOutParam.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="894631">
						<CheckNo>6</CheckNo>
						<CheckType>mvrSafety</CheckType>
						<Name>Modelling&#32;Error&#32;check</Name>
						<RelativePath>Reflector.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="894632">
						<CheckNo>7</CheckNo>
						<CheckType>mvrLivelock</CheckType>
						<Name>Livelock&#32;check</Name>
						<RelativePath>Reflector.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="894633">
						<CheckNo>8</CheckNo>
						<CheckType>mvrDeadlock</CheckType>
						<Name>Deadlock&#32;check</Name>
						<RelativePath>Reflector.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="894634">
						<CheckNo>9</CheckNo>
						<CheckType>mvrDeterminism</CheckType>
						<Name>Deterministic&#32;check</Name>
						<Result>crPassed</Result>
					</Check>
					<Check ID="894635">
						<CheckNo>10</CheckNo>
						<CheckType>mvrSafety</CheckType>
						<Name>Modelling&#32;Error&#32;check</Name>
						<Result>crPassed</Result>
					</Check>
					<Check ID="894636">
						<CheckNo>11</CheckNo>
						<CheckType>mvrDeadlock</CheckType>
						<Name>Deadlock&#32;check</Name>
						<Result>crPassed</Result>
					</Check>
					<Check ID="894637">
						<CheckNo>12</CheckNo>
						<CheckType>mvrRefinement</CheckType>
						<Name>Interface&#32;Compliance&#32;check</Name>
						<Result>crPassed</Result>
					</Check>
					<Check ID="894638">
						<CheckNo>13</CheckNo>
						<CheckType>mvrLivelock</CheckType>
						<Name>Relaxed&#32;Livelock&#32;check</Name>
						<Result>crPassed</Result>
					</Check>
					<Check ID="894639">
						<CheckNo>14</CheckNo>
						<CheckType>mvrDataVariables</CheckType>
						<Name>Data&#32;Variable&#32;check</Name>
						<Result>crPassed</Result>
					</Check>
				</Checks>
				<Fingerprints>
					<Fingerprint ID="894640">
						<Fingerprint>E4AFCA21</Fingerprint>
					</Fingerprint>
					<Fingerprint ID="894641">
						<Fingerprint>803AF950</Fingerprint>
						<RelativePath>OutParam.im</RelativePath>
					</Fingerprint>
					<Fingerprint ID="894642">
						<Fingerprint>8266FF9F</Fingerprint>
						<RelativePath>MultiStepOutParam.im</RelativePath>
					</Fingerprint>
					<Fingerprint ID="894643">
						<Fingerprint>9A555D2B</Fingerprint>
						<RelativePath>Reflector.im</RelativePath>
					</Fingerprint>
				</Fingerprints>
			</VerificationStatus>
		</VerificationStatus>
	</DesignModel>
</asd>
