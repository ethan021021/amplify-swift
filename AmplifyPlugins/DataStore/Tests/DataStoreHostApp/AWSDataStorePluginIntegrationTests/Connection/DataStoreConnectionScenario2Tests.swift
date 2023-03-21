//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSDataStorePlugin
@testable import DataStoreHostApp

/*
 A one-to-one connection where a project has one team,
 with a field you would like to use for the connection.
 ```
 type Project2 @model {
   id: ID!
   name: String
   teamID: ID!
   team: Team2 @connection(fields: ["teamID"])
 }

 type Team2 @model {
   id: ID!
   name: String!
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
 */

class DataStoreConnectionScenario2Tests: SyncEngineIntegrationTestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Team2.self)
            registry.register(modelType: Project2.self)
        }

        let version: String = "1"
    }

    func testSaveTeamAndProjectSyncToCloud() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let team = Team2(name: "name1")
        let project = Project2(teamID: team.id, team: team)
        let syncedTeamReceived = asyncExpectation(description: "received team from sync event")
        let syncProjectReceived = asyncExpectation(description: "received project from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedTeam = try? mutationEvent.decodeModel() as? Team2,
               syncedTeam == team {
                Task {
                    await syncedTeamReceived.fulfill()
                }
                
            } else if let syncedProject = try? mutationEvent.decodeModel() as? Project2,
                      syncedProject == project {
                Task {
                    await syncProjectReceived.fulfill()
                }
                
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        _ = try await Amplify.DataStore.save(team)
        await waitForExpectations([syncedTeamReceived], timeout: networkTimeout)
        
        _ = try await Amplify.DataStore.save(project)

        await waitForExpectations([syncProjectReceived], timeout: networkTimeout)

        let queriedProject = try await Amplify.DataStore.query(Project2.self, byId: project.id)
        XCTAssertEqual(queriedProject, project)
    }

    func testUpdateProjectWithAnotherTeam() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let team = Team2(name: "name1")
        let anotherTeam = Team2(name: "name1")
        var project = Project2(teamID: team.id, team: team)
        let expectedUpdatedProject = Project2(id: project.id, name: project.name, teamID: anotherTeam.id)
        let syncUpdatedProjectReceived = asyncExpectation(description: "received updated project from sync path")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedUpdatedProject = try? mutationEvent.decodeModel() as? Project2,
               expectedUpdatedProject == syncedUpdatedProject {
                Task {
                    await syncUpdatedProjectReceived.fulfill()
                }
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        _ = try await Amplify.DataStore.save(team)
        _ = try await Amplify.DataStore.save(anotherTeam)
        _ = try await Amplify.DataStore.save(project)
        project.teamID = anotherTeam.id
        project.team = anotherTeam
        _ = try await Amplify.DataStore.save(project)

        let queriedProjectOptional = try await Amplify.DataStore.query(Project2.self, byId: project.id)
        XCTAssertNotNil(queriedProjectOptional)
        if let queriedProject = queriedProjectOptional {
            XCTAssertEqual(queriedProject, project)
            XCTAssertEqual(queriedProject.teamID, anotherTeam.id)
        }
        await waitForExpectations([syncUpdatedProjectReceived], timeout: networkTimeout)
    }

    func testDeleteAndGetProjectReturnsNilWithSync() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let team = try await createModelUntilSynced(data: randomTeam())
        let project = try await createModelUntilSynced(data: randomProject(with: team))

        try await deleteModelWaitForSync(data: project)

        // TODO: Delete Team should not be necessary, cascade delete should delete the team when deleting the project.
        // Once cascade works for hasOne, the following code can be removed.
        try await deleteModelWaitForSync(data: team)

        let project2 = try await Amplify.DataStore.query(Project2.self, byId: project.id)
        XCTAssertNil(project2)
    }

    func testDeleteWithValidCondition() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let team = try await createModelUntilSynced(data: randomTeam())
        let project = try await createModelUntilSynced(data: randomProject(with: team))

        try await deleteModelWaitForSync(data: project, predicate: Project2.keys.team.eq(team.id))
        let project2 = try await Amplify.DataStore.query(Project2.self, byId: project.id)
        XCTAssertNil(project2)
    }

    func testDeleteWithInvalidCondition() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let team = try await createModelUntilSynced(data: randomTeam())
        let project = try await createModelUntilSynced(data: randomProject(with: team))

        do {
            try await deleteModelWaitForSync(data: project, predicate: Project2.keys.team.eq("invalidTeamId"))
            XCTFail("Should have failed")
        } catch let error as DataStoreError {
            guard case .invalidCondition = error else {
                XCTFail("\(error)")
                return
            }
        }
        
        let project2 = try await Amplify.DataStore.query(Project2.self, byId: project.id)
        XCTAssertNotNil(project2)
    }

    func testDeleteAlreadyDeletedItemWithCondition() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let team = try await createModelUntilSynced(data: randomTeam())
        let project = try await createModelUntilSynced(data: randomProject(with: team))
        try await deleteModelWaitForSync(data: project)
        let project2 = try await Amplify.DataStore.query(Project2.self, byId: project.id)
        XCTAssertNil(project2)
        try await Amplify.DataStore.delete(project, where: Project2.keys.teamID == team.id)
    }

    func testListProjectsByTeamID() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let team = try await createModelUntilSynced(data: randomTeam())
        let project = try await createModelUntilSynced(data: randomProject(with: team))
        let predicate = Project2.keys.teamID.eq(team.id)
        let projects = try await Amplify.DataStore.query(Project2.self, where: predicate)
        XCTAssertEqual(projects.count, 1)
        XCTAssertEqual(projects[0].id, project.id)
        XCTAssertEqual(projects[0].teamID, team.id)
    }

    private func randomTeam() -> Team2 {
        Team2(name: UUID().uuidString)
    }

    private func randomProject(with team: Team2) -> Project2 {
        Project2(name: UUID().uuidString, teamID: team.id, team: team)
    }
}

extension Team2: Equatable {
    public static func == (lhs: Team2,
                           rhs: Team2) -> Bool {
        return lhs.id == rhs.id
            && lhs.name == rhs.name
    }
}
extension Project2: Equatable {
    public static func == (lhs: Project2, rhs: Project2) -> Bool {
        return lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.teamID == rhs.teamID
    }
}
