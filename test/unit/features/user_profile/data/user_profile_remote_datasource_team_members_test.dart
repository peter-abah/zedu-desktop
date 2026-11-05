import '../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('UserProfileRemoteDataSourceImpl.getTeamMembers', () {
    late MockApiBaseService mockApi;
    late UserProfileRemoteDataSourceImpl datasource;

    setUp(() {
      mockApi = MockApiBaseService();
      datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(apiBaseUrl: '', usesMockData: false),
        apiBaseService: mockApi,
      );
    });

    test('throws a client ApiFailure without a workspace selected', () async {
      await expectLater(
        datasource.getTeamMembers(orgId: null),
        throwsA(
          isA<ApiFailure>().having(
            (failure) => failure.kind,
            'kind',
            ApiFailureKind.client,
          ),
        ),
      );
      verifyNever(
        () => mockApi.get<Map<String, dynamic>>(path: any(named: 'path')),
      );
    });

    test('throws a client ApiFailure for an empty workspace id', () async {
      await expectLater(
        datasource.getTeamMembers(orgId: ''),
        throwsA(isA<ApiFailure>()),
      );
      verifyNever(
        () => mockApi.get<Map<String, dynamic>>(path: any(named: 'path')),
      );
    });

    test('never falls back to a hardcoded organisation', () async {
      when(
        () => mockApi.get<Map<String, dynamic>>(path: any(named: 'path')),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          statusCode: 200,
          data: {'data': <dynamic>[]},
        ),
      );

      await datasource.getTeamMembers(orgId: 'short-id');

      verify(
        () => mockApi.get<Map<String, dynamic>>(
          path: '/organisations/short-id/users',
        ),
      ).called(1);
      verifyNever(
        () => mockApi.get<Map<String, dynamic>>(
          path: '/organisations/019700db-4e22-7f90-a20e-f9116291ef24/users',
        ),
      );
    });

    test(
      'propagates API failures instead of returning an empty list',
      () async {
        when(
          () => mockApi.get<Map<String, dynamic>>(path: any(named: 'path')),
        ).thenThrow(const ApiFailure(message: 'boom'));

        await expectLater(
          datasource.getTeamMembers(orgId: 'org-1'),
          throwsA(isA<ApiFailure>()),
        );
      },
    );

    test('returns the members of the requested organisation', () async {
      when(
        () => mockApi.get<Map<String, dynamic>>(path: any(named: 'path')),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          statusCode: 200,
          data: {
            'data': [
              {
                'id': 'member-1',
                'email': 'teammate@zedu.app',
                'role': 'User',
                'created_at': 'May 4, 2026',
                'name': 'Teammate',
              },
            ],
          },
        ),
      );

      final members = await datasource.getTeamMembers(orgId: 'org-1');

      verify(
        () => mockApi.get<Map<String, dynamic>>(
          path: '/organisations/org-1/users',
        ),
      ).called(1);
      expect(members, hasLength(1));
      expect(members.single.id, 'member-1');
      expect(members.single.email, 'teammate@zedu.app');
    });
  });
}
