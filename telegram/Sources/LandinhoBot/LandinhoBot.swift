@main
public class LandinhoBot {
  init(bot: DefaultVroomBot) {
    self.bot = bot
  }
  let bot: DefaultVroomBot

  public static func main() {
    _ = LandinhoBot(bot: .init())
  }
}
