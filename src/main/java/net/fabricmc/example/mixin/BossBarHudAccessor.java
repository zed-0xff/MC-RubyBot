package net.fabricmc.example.mixin;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;
import org.spongepowered.asm.mixin.gen.Invoker;

import net.minecraft.client.gui.hud.BossBarHud;
import net.minecraft.client.gui.hud.ClientBossBar;

import java.util.Map;
import java.util.UUID;

@Mixin(BossBarHud.class)
public interface BossBarHudAccessor {
    @Accessor
    Map<UUID,ClientBossBar> getBossBars();
}
