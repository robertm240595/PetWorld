return {
    HollowfangWyrm={Id="HollowfangWyrm",Name="Hollowfang Wyrm",Rarity="Epic",Species="Hollowfang Wyrm",
        ModelGenerator="BossTravelService.createWyrm",Health=1200,Power=48,Defence=22,
        Phases={{Id="WOUNDED",HealthFraction=1},{Id="STUNNED",Temporary=true}}},
    Jormungdyrr={Id="Jormungdyrr",Name="Jormungdyrr",Rarity="Ancient",Species="Jörmungandr",
        ModelGenerator="BossTravelService.createJormungdyrr",Health=300000,Power=220,Defence=110,
        RespawnSeconds=14400,EnrageHealthFraction=.30,EnragePowerMultiplier=1.25,
        Phases={{Id="HUNTING",HealthFraction=1},{Id="ENRAGED",HealthFraction=.30},{Id="STUNNED",Temporary=true}}},
}
