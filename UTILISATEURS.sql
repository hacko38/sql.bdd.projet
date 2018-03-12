use Pistons
go

/*------------------------------------------------------------
-- Creation des USER et ROLES
------------------------------------------------------------*/
CREATE ROLE CONTROLEUR;
CREATE ROLE RESP_ATELIER;
CREATE ROLE RESP_PRODUCTION;
CREATE ROLE RESP_QUALITE;
CREATE ROLE RESP_APPLI;
CREATE ROLE MAGASINIER;
go

/*
CREATE LOGIN resp_appli WITH PASSWORD ='resp_appli';
CREATE LOGIN resp_atelier1 WITH PASSWORD ='resp_atelier1';
CREATE LOGIN resp_atelier2	WITH PASSWORD ='resp_atelier2';
CREATE LOGIN resp_production1 WITH PASSWORD ='resp_production1';
CREATE LOGIN resp_production2 WITH PASSWORD ='resp_production2';
CREATE LOGIN controleur1 WITH PASSWORD ='controleur1';
CREATE LOGIN controleur2 WITH PASSWORD ='controleur2';
CREATE LOGIN controleur3 WITH PASSWORD ='controleur3';
CREATE LOGIN magasinier1 WITH PASSWORD ='magasinier1';
CREATE LOGIN magasinier2 WITH PASSWORD ='magasinier2';
CREATE LOGIN magasinier3 WITH PASSWORD ='magasinier3';
CREATE LOGIN resp_qualité1 WITH PASSWORD ='resp_qualité1';
CREATE LOGIN resp_qualité2 WITH PASSWORD ='resp_qualité2';
go
*/




CREATE USER uresp_appli FROM login resp_appli;
CREATE USER uresp_atelier1 FROM login resp_atelier1;
CREATE USER uresp_atelier2	FROM login resp_atelier2;
CREATE USER uresp_production1 FROM login resp_production1;
CREATE USER uresp_production2 FROM login resp_production2;
CREATE USER ucontroleur1 FROM login controleur1;
CREATE USER ucontroleur2 FROM login controleur2;
CREATE USER ucontroleur3 FROM login controleur3;
CREATE USER umagasinier1 FROM login magasinier1;
CREATE USER umagasinier2 FROM login magasinier2;
CREATE USER umagasinier3 FROM login magasinier3;
CREATE USER uresp_qualité1 FROM login resp_qualité1;
CREATE USER uresp_qualité2 FROM login resp_qualité2;
go


-- AFFECTATIONS DES DROITS AUX RÔLES
grant SELECT on VueStocksCategorie to RESP_ATELIER;
grant SELECT on VueTousLots to RESP_ATELIER;
grant EXECUTE on LancerLot to RESP_ATELIER;
grant EXECUTE on AnnulerLot to RESP_ATELIER;
grant EXECUTE on ps_LotsSelect to RESP_ATELIER;
grant EXECUTE on DemarrerLot to RESP_PRODUCTION;
grant EXECUTE on Liberer_presse to RESP_PRODUCTION;
grant EXECUTE on Categorisation to CONTROLEUR;
grant EXECUTE on ArretLot to CONTROLEUR;
grant SELECT on VueStocksCategorie to MAGASINIER;
grant EXECUTE on EntreeStock to MAGASINIER;
grant EXECUTE on SortieStock to MAGASINIER;
grant EXECUTE on Ajouter_modele to RESP_APPLI;
grant EXECUTE on Supprimer_modele to RESP_APPLI;
grant EXECUTE on Ajouter_machine to RESP_APPLI;
grant EXECUTE on Supprimer_machine to RESP_APPLI;
grant EXECUTE on ps_GetRole to public;
/*grant EXECUTE on changeLimit to RESP_APPLI;
grant EXECUTE on pieceCleanUp to RESP_APPLI;*/

-- AFFECTATION ROLES USER
alter role RESP_APPLI add member uresp_appli;
alter role RESP_PRODUCTION add member uresp_production1;
alter role RESP_PRODUCTION add member uresp_production2;
alter role RESP_ATELIER add member uresp_atelier1;
alter role RESP_ATELIER add member uresp_atelier2;
alter role CONTROLEUR add member ucontroleur1;
alter role CONTROLEUR add member ucontroleur2;
alter role CONTROLEUR add member ucontroleur3;
alter role MAGASINIER add member umagasinier1;
alter role MAGASINIER add member umagasinier2;
alter role MAGASINIER add member umagasinier3;
alter role RESP_QUALITE add member uresp_qualité1;
alter role RESP_QUALITE add member uresp_qualité2;


go