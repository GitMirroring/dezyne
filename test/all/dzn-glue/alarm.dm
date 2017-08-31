<?xml version="1.0"?>
<asd OmVersion="10.10.0" BackwardOmVersion="10.10.0" Serializer="2" >
	<DesignModel ID="1170">
		<CodeGenerationLanguage>csp</CodeGenerationLanguage>
		<CodeGenerationVersion>9.2.1</CodeGenerationVersion>
		<DateCreated>20131013T142119</DateCreated>
		<DateModified>20170828T150510</DateModified>
		<Guid>66D86251A0AA42DB88ABD0FED55C7F87</Guid>
		<ModelSignature>BASE64_qU9xMfk39vMaUgNCEID/vjrBFpMmrwjqduJUNm40vFKxvovSK1nQGzgIFwS34uyaEnonywHH/AFiwVhwKS7G38tFtOtk8Vn8sZaO1TVps2vcYU+O35d/LTJW986scdMlAWeP3gXSQPmRt4Lj6AmXoexptlhI3ogczfMogOBSTYtVnLzuKkUeBwX9K71VR+2500cTqddARMNOK8+xJGGlZMLXquR0cksGhkIepWvntYaUsGNIhv17mKgO33nH6cEJ/sc9CpAlCwbyIlq7wQvV5pnSrTN6fu2LlQgGVtDM1/MmGZxQhkkTe227BJ/XpT3WQ+KjR1cHs+zdiKtfdCN40w==</ModelSignature>
		<Name>alarm</Name>
		<ToolVersion>ASD:Suite&#32;ModelBuilder&#32;9.2.7(52388)</ToolVersion>
		<AbstractInterface>
			<AbstractInterface ID="1171">
				<Guid>C87A6402319E4BBABE71CE5B8DC9EACF</Guid>
				<Events>
					<CallEvent ID="1172">
						<Guid>D849ADC0EF514853A0CF4F74E848898A</Guid>
						<Name>StateInvariant</Name>
					</CallEvent>
					<CallEvent ID="1289">
						<Guid>84DEE61F60034238A1EDEC85D19FEA49</Guid>
						<Name>DataInvariant</Name>
					</CallEvent>
				</Events>
				<ReplyEvents>
					<ReplyEvent ID="1173">
						<Guid>EAE2E4DB6FAA4E7681E63D799063AD7D</Guid>
						<Name>NoOp</Name>
					</ReplyEvent>
					<ReplyEvent ID="1174">
						<Guid>8F0CD6C16E1B453883CBC5F7326E1867</Guid>
						<Name>Illegal</Name>
					</ReplyEvent>
					<ReplyEvent ID="1175">
						<Guid>6056DBEB478C4BC0A9C08D1BFB76413D</Guid>
						<Name>Blocked</Name>
					</ReplyEvent>
				</ReplyEvents>
			</AbstractInterface>
		</AbstractInterface>
		<BuiltInInterface>
			<BuiltInInterface ID="1176">
				<Guid>CDB0F64B073F42E88091147C025CD88F</Guid>
				<Events>
					<CallEvent ID="1177">
						<Guid>F29EFB83ED53409d84B64CF57ED6A0F4</Guid>
						<Name>Subscribe</Name>
						<Parameters>
							<USRInterfaceParameter ID="1178">
							</USRInterfaceParameter>
						</Parameters>
					</CallEvent>
					<CallEvent ID="1179">
						<Guid>25B76D8404B54f1d8EA5FF22E47C7CE5</Guid>
						<Name>Unsubscribe</Name>
						<Parameters>
							<USRInterfaceParameter ID="1180">
							</USRInterfaceParameter>
						</Parameters>
					</CallEvent>
					<CallEvent ID="1181">
						<Guid>8CB0CCD035084481B76B3EC0A974FBF5</Guid>
						<Name>Initialise</Name>
						<Parameters>
							<SimpleParameter ID="1182">
								<Direction>pdInOut</Direction>
								<Name>dataVariable</Name>
								<Type>any</Type>
							</SimpleParameter>
						</Parameters>
					</CallEvent>
					<CallEvent ID="1183">
						<Guid>444DBCA038BD4EB3AB79CDBF6E531334</Guid>
						<Name>Invalidate</Name>
						<Parameters>
							<SimpleParameter ID="1184">
								<Direction>pdInOut</Direction>
								<Name>dataVariable</Name>
								<Type>any</Type>
							</SimpleParameter>
						</Parameters>
					</CallEvent>
				</Events>
				<ReplyEvents>
					<ReplyEvent ID="1185">
						<Guid>4689006D1E9D4B5F9F33EE46C7414D81</Guid>
						<Name>VoidReply</Name>
					</ReplyEvent>
				</ReplyEvents>
			</BuiltInInterface>
		</BuiltInInterface>
		<CodeGeneratorSettings>
			<CodeGenInfo ID="1305">
				<Language>c</Language>
				<UseOldTracing>1</UseOldTracing>
				<UseServiceNameInQualifiedNames>0</UseServiceNameInQualifiedNames>
			</CodeGenInfo>
			<CodeGenInfo ID="1306">
				<Language>cpp</Language>
				<UseOldTracing>1</UseOldTracing>
				<UseServiceNameInQualifiedNames>0</UseServiceNameInQualifiedNames>
			</CodeGenInfo>
			<CodeGenInfo ID="1307">
				<Language>csharp</Language>
				<UseOldTracing>1</UseOldTracing>
				<UseServiceNameInQualifiedNames>0</UseServiceNameInQualifiedNames>
			</CodeGenInfo>
			<CodeGenInfo ID="1308">
				<Language>csp</Language>
				<UseOldTracing>1</UseOldTracing>
				<UseServiceNameInQualifiedNames>0</UseServiceNameInQualifiedNames>
			</CodeGenInfo>
			<CodeGenInfo ID="1309">
				<Language>java</Language>
				<UseOldTracing>1</UseOldTracing>
				<UseServiceNameInQualifiedNames>0</UseServiceNameInQualifiedNames>
			</CodeGenInfo>
			<CodeGenInfo ID="1310">
				<Language>tinyc</Language>
				<UseOldTracing>1</UseOldTracing>
				<UseServiceNameInQualifiedNames>0</UseServiceNameInQualifiedNames>
			</CodeGenInfo>
		</CodeGeneratorSettings>
		<ConstructionParameters>
			<SimpleParameter ID="1311">
				<Name>s</Name>
				<Type>int</Type>
			</SimpleParameter>
		</ConstructionParameters>
		<ImplementedService>
			<ServiceDependency ID="1191">
				<ModelGuid>F7EB30AA2502459B9AA08F29111D78BA</ModelGuid>
				<Name>alarm</Name>
				<RelativePath>alarm.im</RelativePath>
				<Declaration>
					<ServiceDeclaration ID="1192">
						<ApplicationInterfaces>
							<ApplicationInterface ID="1193">
								<Guid>ED0B642944FE446394144CC7586E0176</Guid>
								<Name>console_api</Name>
								<Events>
									<CallEvent ID="1194">
										<Guid>A7F6E58D4A164DC7B1796B5F29E03061</Guid>
										<Name>arm</Name>
									</CallEvent>
									<CallEvent ID="1195">
										<Guid>C2631A303D7B48218C636ED6EB0AACE6</Guid>
										<Name>disarm</Name>
									</CallEvent>
								</Events>
								<ReplyEvents>
									<ReplyEvent ID="1196">
										<Guid>0DAC7972187D41FBBCB27FCB5AF3A4DA</Guid>
										<Name>VoidReply</Name>
									</ReplyEvent>
								</ReplyEvents>
							</ApplicationInterface>
						</ApplicationInterfaces>
						<NotificationInterfaces>
							<NotificationInterface ID="1197">
								<Guid>8976C5C822ED414CA6AEAA677E7CBC2D</Guid>
								<Name>console_cb</Name>
								<Events>
									<NotificationEvent ID="1198">
										<Guid>BCA86A367A03454890444F0B50A53ACE</Guid>
										<Name>detected</Name>
									</NotificationEvent>
									<NotificationEvent ID="1199">
										<Guid>9C3919F5B6A648CDAD78FE9A57FF2CFC</Guid>
										<Name>deactivated</Name>
									</NotificationEvent>
								</Events>
							</NotificationInterface>
						</NotificationInterfaces>
					</ServiceDeclaration>
				</Declaration>
			</ServiceDependency>
		</ImplementedService>
		<MainMachine>
			<MainMachine ID="1200">
				<Guid>30CD0E878C07466BAEF36A178DA81DD8</Guid>
				<Name>alarm</Name>
				<StateVariables>
					<StateVariable ID="1201">
						<Guid>B9734BFDCC474D1DAD0F316E994948DF</Guid>
						<InitialValue>false</InitialValue>
						<Name>sounding</Name>
						<VarType>svtBool</VarType>
					</StateVariable>
				</StateVariables>
				<States>
					<State ID="1202">
						<Guid>8CE0C508467242EB9F7ABEE5C7D1889A</Guid>
						<Name>Disarmed</Name>
						<Rules>
							<Rule ID="1203">
								<Event>1172</Event>
								<RuleCases>
									<RuleCase ID="1204">
										<Row>2</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1290">
								<Event>1289</Event>
								<RuleCases>
									<RuleCase ID="1291">
										<Row>3</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1205">
								<Event>1194</Event>
								<RuleCases>
									<RuleCase ID="1206">
										<Row>4</Row>
										<NextState>1207</NextState>
										<Actions>
											<Action ID="1208">
												<Event>1196</Event>
											</Action>
											<Action ID="1209">
												<Event>1210</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="1211">
														<ServiceReference>1212</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1213">
								<Event>1195</Event>
								<RuleCases>
									<RuleCase ID="1214">
										<Row>5</Row>
										<Actions>
											<Action ID="1215">
												<Event>1174</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1216">
								<Event>1217</Event>
								<ServiceReference>1212</ServiceReference>
								<RuleCases>
									<RuleCase ID="1218">
										<Row>6</Row>
										<Actions>
											<Action ID="1219">
												<Event>1174</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1220">
								<Event>1221</Event>
								<ServiceReference>1212</ServiceReference>
								<RuleCases>
									<RuleCase ID="1222">
										<Row>7</Row>
										<Actions>
											<Action ID="1223">
												<Event>1174</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="1207">
						<Guid>BC43232341764A47AD397E6490E243D7</Guid>
						<Name>Armed</Name>
						<Rules>
							<Rule ID="1224">
								<Event>1172</Event>
								<RuleCases>
									<RuleCase ID="1225">
										<Row>9</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1292">
								<Event>1289</Event>
								<RuleCases>
									<RuleCase ID="1293">
										<Row>10</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1226">
								<Event>1194</Event>
								<RuleCases>
									<RuleCase ID="1227">
										<Row>11</Row>
										<Actions>
											<Action ID="1228">
												<Event>1174</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1229">
								<Event>1195</Event>
								<RuleCases>
									<RuleCase ID="1230">
										<Row>12</Row>
										<NextState>1231</NextState>
										<Actions>
											<Action ID="1232">
												<Event>1196</Event>
											</Action>
											<Action ID="1233">
												<Event>1234</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="1235">
														<ServiceReference>1212</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1236">
								<Event>1217</Event>
								<ServiceReference>1212</ServiceReference>
								<RuleCases>
									<RuleCase ID="1237">
										<Row>13</Row>
										<StateUpdate>sounding=true</StateUpdate>
										<NextState>1238</NextState>
										<Actions>
											<Action ID="1239">
												<Event>1198</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1240">
								<Event>1221</Event>
								<ServiceReference>1212</ServiceReference>
								<RuleCases>
									<RuleCase ID="1241">
										<Row>14</Row>
										<Actions>
											<Action ID="1242">
												<Event>1174</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="1238">
						<Guid>66F810AF30404CD58553BAD01383FE99</Guid>
						<Name>Triggered</Name>
						<Rules>
							<Rule ID="1243">
								<Event>1172</Event>
								<RuleCases>
									<RuleCase ID="1244">
										<Row>24</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1294">
								<Event>1289</Event>
								<RuleCases>
									<RuleCase ID="1295">
										<Row>25</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1245">
								<Event>1194</Event>
								<RuleCases>
									<RuleCase ID="1246">
										<Row>26</Row>
										<Actions>
											<Action ID="1247">
												<Event>1174</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1248">
								<Event>1195</Event>
								<RuleCases>
									<RuleCase ID="1249">
										<Row>27</Row>
										<NextState>1231</NextState>
										<Actions>
											<Action ID="1250">
												<Event>1196</Event>
											</Action>
											<Action ID="1251">
												<Event>1234</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="1252">
														<ServiceReference>1212</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1253">
								<Event>1217</Event>
								<ServiceReference>1212</ServiceReference>
								<RuleCases>
									<RuleCase ID="1254">
										<Row>28</Row>
										<Actions>
											<Action ID="1255">
												<Event>1174</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1256">
								<Event>1221</Event>
								<ServiceReference>1212</ServiceReference>
								<RuleCases>
									<RuleCase ID="1257">
										<Row>29</Row>
										<Actions>
											<Action ID="1258">
												<Event>1174</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="1231">
						<Guid>C20844AB51F14600B5AD936774B195EB</Guid>
						<Name>Disarming</Name>
						<Rules>
							<Rule ID="1259">
								<Event>1172</Event>
								<RuleCases>
									<RuleCase ID="1260">
										<Row>16</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1296">
								<Event>1289</Event>
								<RuleCases>
									<RuleCase ID="1297">
										<Row>17</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1261">
								<Event>1194</Event>
								<RuleCases>
									<RuleCase ID="1262">
										<Row>18</Row>
										<Actions>
											<Action ID="1263">
												<Event>1174</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1264">
								<Event>1195</Event>
								<RuleCases>
									<RuleCase ID="1265">
										<Row>19</Row>
										<Actions>
											<Action ID="1266">
												<Event>1174</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1267">
								<Event>1217</Event>
								<ServiceReference>1212</ServiceReference>
								<RuleCases>
									<RuleCase ID="1268">
										<Row>20</Row>
										<NextState>1231</NextState>
										<Actions>
											<Action ID="1269">
												<Event>1173</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="1270">
								<Event>1221</Event>
								<ServiceReference>1212</ServiceReference>
								<RuleCases>
									<RuleCase ID="1271">
										<Guard>sounding</Guard>
										<Row>21</Row>
										<StateUpdate>sounding=false</StateUpdate>
										<NextState>1202</NextState>
										<Actions>
											<Action ID="1272">
												<Event>1199</Event>
											</Action>
										</Actions>
									</RuleCase>
									<RuleCase ID="1273">
										<Guard>otherwise</Guard>
										<Row>22</Row>
										<NextState>1202</NextState>
										<Actions>
											<Action ID="1274">
												<Event>1199</Event>
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
			<ModelBuilderSettings ID="1275">
			</ModelBuilderSettings>
		</ModelBuilderSettings>
		<ServiceReferences>
			<ServiceReference ID="1212">
				<Construction>sensor</Construction>
				<Guid>60E92CFB46744CBB90B6F7A9381E6749</Guid>
				<Name>sensor</Name>
				<Dependency>1276</Dependency>
			</ServiceReference>
			<ServiceReference ID="1277">
				<Construction>siren(s)</Construction>
				<Guid>5FFF1CFDA552420CA5289CE20030CA5B</Guid>
				<Name>siren</Name>
				<Dependency>1278</Dependency>
			</ServiceReference>
		</ServiceReferences>
		<UsedServices>
			<ServiceDependency ID="1276">
				<ModelGuid>0671E01C44104FD99D14ED00DE1C5241</ModelGuid>
				<Name>sensor</Name>
				<RelativePath>sensor.im</RelativePath>
				<Declaration>
					<ServiceDeclaration ID="1279">
						<ApplicationInterfaces>
							<ApplicationInterface ID="1280">
								<Guid>366C2006F349443DB4A4E46FDF206FA7</Guid>
								<Name>sensor_api</Name>
								<Used>1</Used>
								<Events>
									<CallEvent ID="1210">
										<Guid>50411C74EEBD40C18C08E13E5B95CF80</Guid>
										<Name>enable</Name>
									</CallEvent>
									<CallEvent ID="1234">
										<Guid>34586A5093BA4803893639E1E6376412</Guid>
										<Name>disable</Name>
									</CallEvent>
								</Events>
								<ReplyEvents>
									<ReplyEvent ID="1281">
										<Guid>6BF4E5A3D93C443E8253E796385A70CA</Guid>
										<Name>VoidReply</Name>
									</ReplyEvent>
								</ReplyEvents>
							</ApplicationInterface>
						</ApplicationInterfaces>
						<NotificationInterfaces>
							<NotificationInterface ID="1282">
								<Guid>ACC583ADF1FA4243B6696059606DCEA2</Guid>
								<Name>sensor_cb</Name>
								<Used>1</Used>
								<Events>
									<NotificationEvent ID="1217">
										<Guid>506775E8269D48B5B8BEB8D92A428190</Guid>
										<Name>triggered</Name>
									</NotificationEvent>
									<NotificationEvent ID="1221">
										<Guid>32B768584981404B9F7DCD66F7D74156</Guid>
										<Name>disabled</Name>
									</NotificationEvent>
								</Events>
							</NotificationInterface>
						</NotificationInterfaces>
					</ServiceDeclaration>
				</Declaration>
			</ServiceDependency>
			<ServiceDependency ID="1278">
				<ModelGuid>11C7462B347C46CF969782FE6C1473DB</ModelGuid>
				<Name>siren</Name>
				<RelativePath>siren.im</RelativePath>
				<Declaration>
					<ServiceDeclaration ID="1283">
						<ApplicationInterfaces>
							<ApplicationInterface ID="1284">
								<Guid>434D79240FD54202939E4DE2FCECC026</Guid>
								<Name>siren_api</Name>
								<Used>1</Used>
								<Events>
									<CallEvent ID="1285">
										<Guid>F0354ADAC94947A8A9EB3DFE54D937E5</Guid>
										<Name>on</Name>
									</CallEvent>
									<CallEvent ID="1286">
										<Guid>CDF456FEFF96496B99EC9B091F78B386</Guid>
										<Name>off</Name>
									</CallEvent>
								</Events>
								<ReplyEvents>
									<ReplyEvent ID="1287">
										<Guid>348425C930FF4B009D65DCD603C8D50D</Guid>
										<Name>VoidReply</Name>
									</ReplyEvent>
								</ReplyEvents>
							</ApplicationInterface>
						</ApplicationInterfaces>
					</ServiceDeclaration>
				</Declaration>
			</ServiceDependency>
		</UsedServices>
		<VerificationStatus>
			<VerificationStatus ID="1288">
			</VerificationStatus>
		</VerificationStatus>
	</DesignModel>
</asd>
